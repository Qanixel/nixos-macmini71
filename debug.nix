{ config, pkgs, ... }:

{
  # 允许运行预编译的动态链接二进制（VS Code Remote-SSH 服务端、
  # 扩展自带的工具等）。nix-ld 默认提供 zlib/zstd/stdenv.cc.cc/curl/
  # openssl 等常用库；若某个扩展仍报缺库，在
  # programs.nix-ld.libraries 里追加对应库即可。
  programs.nix-ld.enable = true;

  # SSH 断开后保留 user systemd 会话：zellij 服务端和后台任务继续存活，
  # 重新登录后可直接 `zellij attach` 恢复工作现场。
  users.users.qanix.linger = true;
}
