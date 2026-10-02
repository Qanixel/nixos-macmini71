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
  ];

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
  networking.wireless.iwd.enable = true; # 网传 iwd 有奇效
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
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.54"
  ];

  # ==================== 桌面环境与 1080p 分辨率优化 ====================
  services.xserver.enable = true;

  services.xserver.displayManager.lightdm.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "qanix";

  # 配置 PAM 允许 qanix 在 lightdm 服务中无需密码登录
  security.pam.services.lightdm = {
    text = ''
      auth requisite pam_nologin.so
      auth sufficient pam_succeed_if.so user = qanix
      auth include login
      account include login
      password include login
      session include login
    '';
  };

  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.autoRepeatDelay = 200;
  services.xserver.autoRepeatInterval = 30;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # 通过 Xorg 配置文件强制将外接显示器默认/最大分辨率限制为 1080p
  # 注：若你的外接接口名称不是 HDMI-1 或 DP-1，可通过 xrandr 查看后修改
  services.xserver.xrandrHeads = [
    {
      output = "HDMI-2";
      primary = true;
      monitorConfig = ''
        Option "PreferredMode" "1920x1080"
      '';
    }
  ];

  # ==================== 音频与服务 ====================
  services.printing.enable = false;

  #services.pulseaudio.enable = false;
  #security.rtkit.enable = true;
  #services.pipewire = {
  #  enable = true;
  #  alsa.enable = true;
  #  alsa.support32Bit = true;
  #  pulse.enable = true;
  #};

  services.openssh.enable = true;

  # ==================== 用户与软件包 ====================
  users.users."qanix" = {
    isNormalUser = true;
    description = "Qanix";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  security.sudo.wheelNeedsPassword = false;

  programs.firefox.enable = true;


  environment.variables.EDITOR = "vim";
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    pciutils
    wget
    fish
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
