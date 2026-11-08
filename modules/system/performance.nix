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

  # 注：本机 Apple SSD 的 AHCI 控制器对 link_power_management_policy 的所有非
  # max_performance 写入都返回 EOPNOTSUPP/EINVAL（2026-11-08 实测），因此不启用 SATA ALPM。

  # 性能/功耗观测工具；intel_gpu_top 也补上了 bilibili.nix 文档里提到但当前未安装的命令。
  environment.systemPackages = with pkgs; [
    powertop
    linuxPackages.turbostat
    linuxPackages.cpupower
    intel-gpu-tools
  ];
}
