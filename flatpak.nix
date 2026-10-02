{config, pkgs, ...}:

{
  services.flatpak.enable = true;
  environment.systemPackages = [ pkgs.gnome-software ];

  # XFCE 环境下的 XDG Portal 关键修复
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk"; # 强制要求 Flatpak 使用 GTK 后端
  };

  # 确保 XFCE 能够正确读取 Flatpak 的应用快捷方式和图标
  environment.profiles = [
    "$HOME/.local/share/flatpak/exports"
    "/var/lib/flatpak/exports"
];

}

