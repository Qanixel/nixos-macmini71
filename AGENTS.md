# AGENTS.md — Macmini (Mac Mini 7,1) 远程运维与配置指南

本文件面向后续接手的 AI Agent 或人类维护者，说明如何连接这台机器、修改并部署 NixOS 配置、
以及排查常见问题。**重建（`nixos-rebuild`）只由用户手动执行**，Agent 只能编辑、求值和做运行态检查。

## 1. 设备概况

| 项目 | 值 |
| --- | --- |
| 硬件 | Apple Mac Mini 7,1（Late 2014，Haswell） |
| 系统 | NixOS 26.11（nixos-unstable），x86_64-linux |
| 主机名 | `Macmini` |
| 局域网地址 | `192.168.1.132`，SSH 端口 `22` |
| 日常用户 | `qanix`（uid 1000，`wheel` 组，sudo 免密） |
| 配置仓库 | `/home/qanix/nixos-macmini71`（即 flake 根目录） |
| 远程仓库 | `https://github.com/Qanixel/nixos-macmini71`（推送用 SSH remote，见 §7） |
| 引导 | systemd-boot，保留最近 5 个 generation；`/boot` 为 vfat |

## 2. 连接方式

### SSH

本机 `~/.ssh/config` 中已配置别名（示例）：

```sshconfig
Host Macmini
    HostName 192.168.1.132
    User qanix
    IdentityFile ~/.ssh/id_ed25519
```

```bash
ssh Macmini                 # 公钥登录（主用）
ssh qanix@192.168.1.132     # 密码登录仍作为后备（server.nix 显式保留）
```

服务端 `PermitRootLogin = "no"`，请始终用 `qanix` 登录后再 `sudo`。

### SFTP / SCP / rsync

OpenSSH 默认的 `sftp-server` 子系统已启用，无需额外服务：

```bash
sftp Macmini
scp foo.nix Macmini:/home/qanix/nixos-macmini71/
rsync -av --exclude .git ./ nixos-macmini71/   # 在远端仓库目录内执行时注意方向
rsync -av --exclude .git Macmini:/home/qanix/nixos-macmini71/ ~/backup-config/
```

从其他机器回传文件时**不要带 owner/group**（普通用户无权 chown）：

```bash
rsync -rlpt --no-owner --no-group ./local-dir/ Macmini:/home/qanix/nixos-macmini71/
```

### VS Code Remote-SSH

1. 安装扩展 `ms-vscode-remote.remote-ssh`。
2. 连接 `qanix@192.168.1.132`（或上面 `Macmini` 别名），首次会往 `~/.vscode-server` 安装服务端。
3. `programs.nix-ld.enable = true`（`debug.nix`）让 VS Code 服务端及扩展附带的预编译二进制可直接运行；
   若某扩展报缺共享库，把它加入 `programs.nix-ld.libraries` 后重建。
4. 推荐再装 `jnoortheen.nix-ide`，语言服务器选 `nixd`（本仓库 `home.nix` 已安装），格式化用 `nixfmt`。

### zellij 持久会话

`home.nix` 已启用 `programs.zellij`，`debug.nix` 已设置 `users.users.qanix.linger = true`，
因此 SSH 断开后 user systemd 会话不退出，zellij 服务端继续存活：

```bash
ssh Macmini
zellij attach            # 直接接回既有会话（有多个时用 zellij ls 选择）
zellij attach -c work    # 新建/接入名为 work 的会话
```

退出会话（不杀进程）用 `Ctrl-o d`；彻底结束用 `zellij kill-session <name>`。

## 3. 仓库结构与模块地图

```
flake.nix                     # flake 入口；nixosConfigurations.Macmini
configuration.nix             # 系统主体：引导、网络、用户、软件包、GC
server.nix                    # OpenSSH 设置 + mosh
debug.nix                     # 远程调试支撑：nix-ld、linger
home.nix                      # home-manager 用户环境（shell、CLI、zellij、direnv）
home/spotify.nix              # home-manager 子模块（spicetify）
hardware-configuration.nix    # 磁盘/硬件探测结果，禁止手改
desktop.nix                   # XFCE + lightdm（qanix 自动登录）
remote.nix                    # uinput、KDE Connect、onboard 屏幕键盘
terminal.nix                  # kitty terminfo
bilibili.nix                  # bilibili 客户端与 mpv/yt-dlp
mpfan.nix / timer.nix / pipewire.nix / flatpak.nix
TODO.md                       # 待办（配置分体化等）
```

规则：新功能尽量做成独立 `.nix` 模块，再在 `configuration.nix` 的 `imports`（系统级）
或 `home.nix` 的 `imports`（用户级）中挂载。不要手改 `hardware-configuration.nix`。

## 4. 修改 → 求值 → 重建 → 复核

```bash
# 1) 编辑后先做语法检查（在仓库根目录）
nix-instantiate --parse configuration.nix >/dev/null
nixfmt --check .              # 可选，保持风格
deadnix -f .                  # 可选，查未使用绑定
statix check .                # 可选，lint

# 2) 只求值、不构建，验证 flake 能完整展开
nix eval --raw .#nixosConfigurations.Macmini.config.system.build.toplevel.drvPath

# 3) 由用户执行重建（Agent 不要执行）
sudo nixos-rebuild switch --flake /home/qanix/nixos-macmini71#Macmini   # 或别名 nu

# 4) 重建后复核运行态
sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|kbdinteractive'
loginctl show-user qanix -p Linger
command -v zellij nix-diff nix-tree nixd nixfmt deadnix statix
```

回滚：

```bash
sudo nixos-rebuild switch --rollback     # 回到上一个 generation
nixos-rebuild list-generations           # 查看全部 generation
# 无法登录时：重启，在 systemd-boot 菜单里选旧 generation 启动
```

## 5. 调试工具箱

已随 `home.nix` 安装：`nix-diff`、`nix-tree`、`nixfmt`、`deadnix`、`statix`、`nixd`、
`nix-output-monitor`（`nom`）、`direnv` + `nix-direnv`、`zellij`。

```bash
nix eval .#nixosConfigurations.Macmini.config.services.openssh.settings   # 查某个最终配置值
nix repl .#nixosConfigurations.Macmini                                    # 进入配置求值环境
nix-diff <old.drv> <new.drv>          # 两个 derivation 的输入差异（升级/改动影响面）
nix-tree /run/current-system          # 交互式看闭包与依赖
nix why-depends ./result <pkg>        # 解释为什么闭包里包含某包
nom build .#nixosConfigurations.Macmini.config.system.build.toplevel
nix log <drv-or-store-path>           # 查看构建日志
journalctl -u sshd -b --no-pager      # SSH 服务日志
journalctl -u display-manager -b      # 登录管理器
systemctl --user status               # linger 下的用户会话
systemctl status nix-daemon
dmesg -w                              # 硬件 / 驱动（Wi-Fi、GPU）
```

direnv：在仓库根执行一次 `direnv allow` 后，进入目录自动加载 `devShell`（若存在）；
没有 `flake.nix` 的 `devShell` 时不会生效。

## 6. 权限与安全基线

- 家目录 `700`、`~/.ssh` `700`、`authorized_keys` `600`；新增公钥直接追加到
  `~/.ssh/authorized_keys`，不要放宽目录权限。
- `PermitRootLogin = "no"`；密码登录保留为后备，公钥是主认证。等所有常用设备都有公钥后，
  可把 `PasswordAuthentication` 改为 `false`（改 `server.nix` 并重建）。
- GitHub 访问使用仓库级 **Deploy Key**：私钥 `~/.ssh/github_qanix`（`600`），只对本仓库有写权限，
  机器上不保存 GitHub token，也不用 `gh`。
- 提交前确认没有私钥、token、密码进入仓库；`.gitignore` 已忽略 `result/`、`.direnv/`、
  `.nixos-test-history`。

## 7. GitHub 推送（Deploy Key）

```bash
ssh -T git@github.com                 # 应返回 "Hi Qanixel/nixos-macmini71! You've successfully authenticated..."
cd /home/qanix/nixos-macmini71
git remote -v                         # origin 应为 git@github.com:Qanixel/nixos-macmini71.git
git push origin main
```

`~/.ssh/config` 中的 GitHub 段（`600`）：

```sshconfig
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_qanix
    IdentitiesOnly yes
```

Deploy key 需在仓库 `Settings → Deploy keys` 添加，并勾选 **Allow write access**；
忘记勾选时 push 会报 `Permission denied`。

## 8. 已知坑

- **Broadcom BCM4360 Wi-Fi**：使用 `broadcom_sta` 并 blacklist 开源驱动；`broadcom-sta` 是 insecure
  包，版本号固定在 `configuration.nix` 的 `permittedInsecurePackages` 中。升级内核后若求值报
  insecure 错误，需把新版本号加入该列表。Wi-Fi 由 `iwd` 后端 + NetworkManager 管理，
  用 `nmcli device wifi list` / `nmcli device wifi connect`。
- **视频硬解**：Haswell 仅支持 H.264，H.265/VP9 会走软解（见 `bilibili.nix` 注释）。
- **home-manager 文件冲突**：已有同名文件会被重命名为 `*.backup`（`backupFileExtension = "backup"`），
  冲突时先看 `.backup` 再决定去留。
- **镜像**：`mirrors.enable = true`（mirrors-nix）会替换 substituter；若下载报 404/超时，
  检查 `/etc/nix/nix.conf` 的 `substituters`，必要时临时 `--option substituters https://cache.nixos.org`。
- **systemd-boot 只留 5 个 generation**：`configurationLimit = 5`，旧代会被清理，回滚要趁早。

## 9. 常用命令速查

```bash
ssh Macmini                                  # 登录
zellij attach                                # 接回持久会话
sudo nixos-rebuild switch --flake .#Macmini  # 重建（用户执行）
sudo nixos-rebuild switch --rollback         # 回滚
nix flake check                              # flake 健全性检查
nix eval --raw .#nixosConfigurations.Macmini.config.system.build.toplevel.drvPath
git -C /home/qanix/nixos-macmini71 status
git -C /home/qanix/nixos-macmini71 push origin main
```
