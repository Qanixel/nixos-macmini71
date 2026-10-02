{ config, pkgs, ... }:

{
  # 1. 定义定时器（Timer）
  systemd.timers.daily-shutdown = {
    description = "Trigger Daily Shutdown";
    timerConfig = {
      OnCalendar = "*-*-* 21:45:00";
    };
    wantedBy = [ "timers.target" ];
  };

  # 2. 定义对应的服务（Service）
  # 提示：NixOS 默认会寻找与定时器同名（daily-shutdown）的服务
  systemd.services.daily-shutdown = {
    description = "Daily Automated Shutdown Service";
    documentation = [ "man:systemd-poweroff(8)" ];
    serviceConfig = {
      Type = "oneshot";
      # 使用 Nix 语法引用 systemd 包中的绝对路径
      ExecStart = "${pkgs.systemd}/bin/systemctl poweroff";
    };
  };

  # 确保系统安装了包含 rtcwake 的工具包
  environment.systemPackages = [ pkgs.util-linux ];

  # 1. 关机前设置 RTC 唤醒闹钟的服务
  systemd.services.set-rtc-wakeup-before-shutdown = {
    description = "Set RTC Wake Alarm Before Shutdown";
    
    # 对应原文件的 [Unit] 块
    unitConfig = {
      DefaultDependencies = "no";
    };
    before = [ "shutdown.target" "reboot.target" ];
    
    # 对应原文件的 [Service] 块
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # 使用 Nix 语法引入绝对路径，并在脚本中正确转义 $ 符号
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.util-linux}/bin/rtcwake -m no -t \$(${pkgs.coreutils}/bin/date -d \"tomorrow 07:15\" +%s)'";
    };
    
    # 对应原文件的 [Install] 块
    wantedBy = [ "shutdown.target" ];
  };
}
