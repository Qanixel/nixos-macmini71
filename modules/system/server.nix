{ config, pkgs, ... }:

{
  # 1. 优化的 OpenSSH 配置
  services.openssh = {
    enable = true;
    settings = {
      UseDns = false;               # 解决连接卡顿
      AllowTcpForwarding = true;    # VS Code Remote-SSH / 端口转发
      AllowAgentForwarding = true;

      # 禁止 root 直接 SSH；管理操作统一走 qanix + sudo
      PermitRootLogin = "no";

      # 保留密码登录作为后备（主力认证仍是公钥，见 AGENTS.md）
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;

      # 长连接
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
    };
  };

  # 2. 启用 Mosh 支持移动端防断线
  programs.mosh.enable = true;

  # 3. SFTP 子系统由 OpenSSH 默认启用（sftp-server），无需额外配置。
  #    客户端可用：sftp / scp / rsync over ssh / VS Code Remote-SSH。
}

