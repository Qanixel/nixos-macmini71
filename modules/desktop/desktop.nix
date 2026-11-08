{ config, pkgs, ... }: {

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the Xfce Desktop Environment
  services.xserver.desktopManager.xfce.enable = true;
  
  # Configure the Display Manager (e.g., LightDM is standard for Xfce)
  services.displayManager.defaultSession = "xfce";
  services.xserver.displayManager.lightdm.enable = true;

  # Optional: Install extra Xfce goodies and tools
  environment.systemPackages = with pkgs; [
    xfce4-pulseaudio-plugin # Volume applet for the panel
    xfce4-whiskermenu-plugin # Modern application menu
  ];

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "qanix";

  # Keyring
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.seahorse.enable = true;

  services.xserver.autoRepeatDelay = 200;
  services.xserver.autoRepeatInterval = 30;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # 注：若外接接口名称可通过 xrandr 查看后修改
  services.xserver.xrandrHeads = [
    {
      output = "HDMI-2";
      primary = true;
      monitorConfig = ''
        Option "PreferredMode" "1920x1080"
      '';
    }
  ];
}

