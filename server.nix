{ config, pkgs, ... }:

{
  # 1. 优化的 OpenSSH 配置
  services.openssh = {
    enable = true;
    settings = {
      UseDns = false;               # 解决连接卡顿
      AllowTcpForwarding = true;    # 优化 VS Code / 转发
      AllowAgentForwarding = true;

      # 长连接
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
    };
  };

  # 2. 启用 Mosh 支持移动端防断线
  programs.mosh.enable = true;

}

