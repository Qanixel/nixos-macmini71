# nixos-macmini71

Mac Mini 7,1（Late 2014，Haswell）上的 NixOS 配置，nixos-unstable + home-manager。

- 主机名：`Macmini`，局域网地址 `192.168.1.132`
- 重建：`sudo nixos-rebuild switch --flake .#Macmini`（由机器上的用户执行）
- 远程连接、调试工具、模块地图与回滚流程：见 [AGENTS.md](./AGENTS.md)

## 快速开始

```bash
ssh Macmini                     # 公钥登录（密码可作后备）
cd /home/qanix/nixos-macmini71
nix eval --raw .#nixosConfigurations.Macmini.config.system.build.toplevel.drvPath
```
