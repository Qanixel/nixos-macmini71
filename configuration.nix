# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports = [
    ./mpfan.nix
    ./bilibili.nix
    ./timer.nix
    ./pipewire.nix
    ./flatpak.nix
    ./remote.nix
    ./server.nix
    ./debug.nix
    ./desktop.nix
    ./terminal.nix
  ];

  mirrors.enable = true;

  # ==================== 引导与系统基础 ====================
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # ==================== 网络与主机名 ====================
  networking.hostName = "Macmini";
  # NetworkManager 的 iwd 后端（比 wpa_supplicant 连接更快更稳）。
  # 注意：iwd 后端已隐含启用 iwd；显式打开 networking.wireless.iwd
  # 是为了独立使用 iwctl 排查问题，二者不冲突。
  networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  # ==================== 硬件与驱动（Broadcom Wi-Fi） ====================
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  hardware.enableAllFirmware = true;
  boot.blacklistedKernelModules = [ "b43" "bcma" "brcmfmac" "brcmsmac" "ssb" "mac80211" ];

  nixpkgs.config.allowUnfree = true;
  # broadcom-sta 被标记为 insecure，版本号会随内核升级变化，
  # rebuild 报版本不匹配时按提示更新此列表。
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.54"
    "broadcom-sta-6.30.223.271-59-7.2.7"
    "broadcom-sta-6.30.223.271-63-6.18.59"
  ];

  # ==================== 用户与软件包 ====================

  users.users.qanix = {
    isNormalUser = true;
    description = "Qanix";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.firefox.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;

  environment.variables.EDITOR = "vim";
  environment.systemPackages = with pkgs; [
    vim-full
    git
    curl
    pciutils
    wget
  ];

  # ==================== 系统维护与 GC ====================

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "26.05";
}
