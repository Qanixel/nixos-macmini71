{ pkgs, ... }:

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
    wireplumber.extraConfig = {
      # 采样率与缓冲：48 kHz / 1024 frames，兼顾兼容性与延迟。
      #
      # 这里刻意不设置 channelmix.max-volume / lock-volumes：
      # 设备音量使用 PipeWire 原生范围，滑块全量程有效。
      # 峰值保护由 EasyEffects 的 limiter 负责（见 home/audio.nix），
      # 不再用隐藏的设备级音量上限来防削波。
      "10-clock-rate" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
        };
      };
    };
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
