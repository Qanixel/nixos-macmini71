{ config, pkgs, ... }:

let
  wakeTime = "07:15";
  shutdownTime = "21:45:00";
in
{
  systemd.services.daily-shutdown = {
    description = "Set RTC wake alarm and power off";
    serviceConfig = {
      Type = "oneshot";
      # 先设置 RTC 唤醒闹钟，再关机
      ExecStart = pkgs.writeShellScript "daily-shutdown.sh" ''
        set -euo pipefail
        ${pkgs.util-linux}/bin/rtcwake -m no -t "$(${pkgs.coreutils}/bin/date -d 'tomorrow ${wakeTime}' +%s)"
        ${pkgs.systemd}/bin/systemctl --no-block poweroff
      '';
    };
  };

  systemd.timers.daily-shutdown = {
    description = "Trigger daily shutdown at ${shutdownTime}";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* ${shutdownTime}";
      Persistent = true;   # 错过时间后开机补触发
    };
  };
}
