{ config, pkgs, lib, ... }:

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
      # ② 音量硬上限（★ 当前已启用：params.ampMaxVolumePercent = 30）
      #
      #    下面这段只在 ampMaxVolumePercent 非 null 时才会生成规则；
      #    改成 null 即完全关闭上限（不会留下任何残留配置）。
      #
      #    机制（已在上游源码核实，不是猜测）：
      #      PipeWire 的 channelmix 阶段有 channelmix.max-volume /
      #      min-volume / lock-volumes 三个属性，
      #      spa/plugins/audioconvert/audioconvert.c 里对音量做
      #          SPA_CLAMPF(props.volume, min_volume, max_volume)
      #      并以 SPA_PROP_volumeMax 上报给上层。
      #      用 WirePlumber 的 monitor.alsa.rules + update-props 把它设到
      #      某个 sink 节点上，就得到"混音器随便拉、实际增益被夹住"的效果。
      #
      #    ⚠️ 单位是**线性**音量，不是界面上的百分比：
      #         线性 = (界面百分比 / 100)³
      #       界面 30% → 0.027（不是 0.3！两者差 10 倍以上）
      #       这是 PulseAudio 风格的三次方曲线，下面第 ③ 段有完整换算表。
      #
      #    与"记住上次音量"的关系：上限只夹峰值，不改动你当前的音量值，
      #    所以两者可以共存。默认 null 时下面的规则根本不会生成。
      // (lib.optionalAttrs (30 != null) (
        let
          p = 30.0 / 100.0;
          cubed = p * p * p;
          # 保留 4 位小数，避免 0.026999999999999996 这种难核对的值
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
                  # 想连"滑块也拉不动"就再加一行（上游同样有实现：
                  # channelmix.lock-volumes 会直接忽略所有音量/静音改动）：
                  # "channelmix.lock-volumes" = true;
                };
              }
            ];
          };
        }
      ));
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
