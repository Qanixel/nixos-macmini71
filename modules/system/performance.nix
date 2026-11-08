{ pkgs, ... }:

{
  # 16 GiB 内存取 25%（约 3.8 GiB）做 zstd 压缩交换，缓冲 Electron/Firefox/构建的内存峰值。
  # 这不是把 SSD 当 swap：zram 完全在内存里，延迟低，也不会增加磁盘写入。
  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };

  # 面向 zram 的常见调优：优先把匿名页换到 zram，减少一次换页的簇大小，保留 inode/dentry 缓存。
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
  };

  # SATA 链路省电。Apple SSD 支持 DIPM 时会生效；不支持时驱动会忽略，保持原策略，无副作用。
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
  '';

  # 性能/功耗观测工具；intel_gpu_top 也补上了 bilibili.nix 文档里提到但当前未安装的命令。
  environment.systemPackages = with pkgs; [
    powertop
    linuxPackages.turbostat
    linuxPackages.cpupower
    intel-gpu-tools
  ];
}
