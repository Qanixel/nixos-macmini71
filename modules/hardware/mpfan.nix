{ config, pkgs, ... }:

{
  # 1. 強制載入 Mac 硬體感測器與 CPU 溫度的核心模組
  boot.kernelModules = [ "applesmc" "coretemp" ];

  # 2. 啟用 Mac 專用的 mbpfan 風扇控制服務
  services.mbpfan = {
    enable = true;
    
    # 以下為適合 Mac Mini 7,1 的推薦溫控曲線（可依個人喜好微調）
    settings = {
      general = {
        min_fan_speed = 1800;   # Mac Mini 預設最低轉速（靜音）
        max_fan_speed = 4500;   # 最高轉速
        low_temp = 55;          # 低於 55 度時維持最低轉速
        high_temp = 72;         # 高於 72 度時開始全速運轉
        max_temp = 86;          # 臨界溫度
      };
    };
  };
}

