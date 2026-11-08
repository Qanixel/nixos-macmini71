{ pkgs, ... }:

{
  services.flatpak.enable = true;
  environment.systemPackages = [ pkgs.gnome-software ];

  # XFCE 环境下的 XDG Portal 关键修复
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk"; # 强制要求 Flatpak 使用 GTK 后端
  };

  # 确保 XFCE 能够正确读取 Flatpak 的应用快捷方式和图标。
  # 注意：sessionVariables 在 /etc/set-environment 中被 shell 展开，
  # 所以这里 $HOME 能正确展开（environment.profiles 中则不会）。
  environment.sessionVariables.XDG_DATA_DIRS = [
    "$HOME/.local/share/flatpak/exports/share"
    "/var/lib/flatpak/exports/share"
  ];
}

