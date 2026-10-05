{ config, pkgs, lib, ... }:

let
  # 可在此处方便地调整音量硬上限百分比（例如设置为 30，或设为 null 完全关闭限制）
  ampMaxVolumePercent = 60;
in
{
  # ═══════════════════════════════════════════════════════════
  #  3) 音频：PipeWire（EasyEffects 的前置条件）
  # ═══════════════════════════════════════════════════════════
  #  EasyEffects 是 PipeWire 的效果器，必须先有 PipeWire。
  #  PipeWire 同时提供 PulseAudio 与 JACK 兼容层，
  #  所以老的 PulseAudio 程序（浏览器、mpv）无需任何改动。
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false; # 本机没有 32 位音频程序，省一点体积
    pulse.enable = true; # 兼容层：让 PulseAudio 程序照常工作
    jack.enable = false; # 不用专业音频工作站，关掉 JACK 图层

    # ── WirePlumber 配置 ────────────────────────────────────
    # 每一项会写成 wireplumber 配置目录下的一个 .conf 文件
    # （名字就是下面的键，所以用数字前缀控制加载顺序）。
    wireplumber.extraConfig =
      {
        # ① 采样率与缓冲：给 EasyEffects 留出处理余量，
        #    又不至于因为缓冲太大而在机械盘上产生爆音。
        "10-clock-rate" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 1024;
          };
        };
      }
      # ② 音量硬上限配置
      // lib.optionalAttrs (ampMaxVolumePercent != null) (
        let
          p = ampMaxVolumePercent / 100.0;
          cubed = p * p * p;
          # 保留 4 位小数，避免出现冗长的浮点数
          linear = builtins.floor (cubed * 10000 + 0.5) / 10000.0;
        in
        {
          "51-usb-amp-volume-cap" = {
            "monitor.alsa.rules" = [
              {
                matches = [ { "node.name" = "~alsa_output\\.usb-.*Musical_Fidelity.*"; } ];
                actions."update-props" = {
                  "channelmix.max-volume" = linear;
                  # 显式写出下限（默认就是 0，写出来是为了让规则自解释）
                  "channelmix.min-volume" = 0.0;
                  # 提示：若想让滑块也锁死，可取消下方注释
                  "channelmix.lock-volumes" = true;
                };
              }
            ];
          };
        }
      );
  };

  # 实时调度权限：EasyEffects 的压缩器/限幅器需要实时优先级，
  # 否则在 CPU 负载高时会产生爆音（老 CPU 尤其明显）。
  security.rtkit.enable = true;

  # 明确关闭 PulseAudio：它和 PipeWire 的 pulse 兼容层不能共存
  services.pulseaudio.enable = false;

  # 图形化音量控制（PipeWire 也能用）
  environment.systemPackages = with pkgs; [
    pavucontrol
    alsa-utils # alsamixer / aplay：排查声卡问题时比图形界面有用
  ];
}
