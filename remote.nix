{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ onboard ];
  programs.dconf.enable = true;

  # 开启 NixOS 官方的 uinput 支持（它会自动加载内核模块并创建 uinput 组）
  hardware.uinput.enable = true;

  # 将你的用户加入自动生成的 uinput 用户组
  users.users.qanix.extraGroups = [ "uinput" "input" ]; 


  # 启用 KDE Connect 模块
  programs.kdeconnect.enable = true;

}

