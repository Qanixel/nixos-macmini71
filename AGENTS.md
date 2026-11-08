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
ssh qanix@192.168.1.132     # 密码登录仍作为后备（modules/system/server.nix 显式保留）
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
3. `programs.nix-ld.enable = true`（`modules/system/debug.nix`）让 VS Code 服务端及扩展附带的预编译二进制可直接运行；
   若某扩展报缺共享库，把它加入 `programs.nix-ld.libraries` 后重建。
4. 推荐再装 `jnoortheen.nix-ide`，语言服务器选 `nixd`（本仓库 `home/packages.nix` 已安装），格式化用 `nixfmt`。

### zellij 持久会话

`home/shell.nix` 已启用 `programs.zellij`，`modules/system/debug.nix` 已设置 `users.users.qanix.linger = true`，
因此 SSH 断开后 user systemd 会话不退出，zellij 服务端继续存活：

```bash
ssh Macmini
zellij attach            # 直接接回既有会话（有多个时用 zellij ls 选择）
zellij attach -c work    # 新建/接入名为 work 的会话
```

退出会话（不杀进程）用 `Ctrl-o d`；彻底结束用 `zellij kill-session <name>`。

## 3. 仓库结构与模块地图

```
flake.nix                                  # flake 入口；nixosConfigurations.Macmini
hosts/Macmini/default.nix                  # 系统主体：引导、网络、用户、软件包、GC
hosts/Macmini/hardware-configuration.nix   # 磁盘/硬件探测结果，禁止手改
modules/system/server.nix                  # OpenSSH 设置 + mosh
modules/system/debug.nix                   # 远程调试支撑：nix-ld、linger
modules/system/performance.nix             # 性能/功耗：zram、sysctl、观测工具（SATA ALPM 本机不支持）
modules/system/terminal.nix                # kitty terminfo
modules/hardware/mpfan.nix                 # 风扇控制
modules/services/pipewire.nix              # 音频
modules/services/flatpak.nix               # Flatpak
modules/services/timer.nix                 # 定时任务
modules/desktop/desktop.nix                # XFCE + lightdm（qanix 自动登录）
modules/desktop/remote.nix                 # uinput、KDE Connect、onboard 屏幕键盘
modules/desktop/bilibili.nix               # bilibili 客户端与 mpv/yt-dlp
home/default.nix                           # home-manager 用户入口（imports / 身份 / stateVersion）
home/packages.nix                          # 用户级 CLI 与 GUI 软件包
home/shell.nix                             # 别名、bash/zsh/fish、fzf、zoxide、zellij、direnv
home/programs.nix                          # git、starship、alacritty
home/xfce.nix                              # XFCE 电源管理：DPMS 熄屏
home/audio.nix                             # EasyEffects 输出处理与安全限幅
home/spotify.nix                           # home-manager 子模块（spicetify）
TODO.md                                    # 待办
```

规则：系统模块放到 `modules/<system|hardware|services|desktop>/`，用户模块放到 `home/`，
然后在对应入口的 `imports` 中挂载——系统级是 `hosts/Macmini/default.nix`，用户级是
`home/default.nix`。不要手改 `hosts/Macmini/hardware-configuration.nix`；
`nixos-generate-config` 生成的新文件需要手动覆盖到该路径。

## 4. 修改 → 求值 → 重建 → 复核

```bash
# 1) 编辑后先做语法检查（在仓库根目录）
nix-instantiate --parse $(git ls-files '*.nix') >/dev/null
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
systemctl --user is-active easyeffects

# 5) 性能/功耗复核（详见下方“性能与功耗”）
systemd-analyze
zramctl; swapon --show
sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure
cat /sys/class/scsi_host/host0/link_power_management_policy
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled
```

### 性能与功耗

`modules/system/performance.nix` 做三项系统级低风险调整；桌面 DPMS 在 `home/xfce.nix`，两者均可独立回滚。

| 项目 | 配置 | 复核 |
| --- | --- | --- |
| zram swap | 16 GiB 的 25%，zstd，priority 100 | `zramctl`、`swapon --show`、`cat /sys/block/zram0/comp_algorithm` |
| zram 相关 sysctl | `swappiness=100`、`page-cluster=0`、`vfs_cache_pressure=50` | `sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure` |
| 启动菜单 | `boot.loader.timeout = 1`（原 5 秒） | `systemd-analyze` 看 loader 时间；开机按方向键/空格可停住菜单 |

SATA ALPM 实测不可用：本机 Apple SSD 的 AHCI 控制器对 `link_power_management_policy` 的所有非
`max_performance` 写入都返回 `EOPNOTSUPP`/`EINVAL`，因此配置中没有 udev 规则；
`/sys/class/scsi_host/host0/link_power_management_policy` 保持 `max_performance` 属于预期。

`home/xfce.nix` 打开 XFCE 的 DPMS：空闲 10 分钟挂起、15 分钟关显示器。若看视频时被误熄屏，
把 `dpms-on-ac-sleep/off` 改大或删除该属性；运行时可用
`xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false` 临时关闭。

功耗采样（RAPL package，不能代表显示器等墙插功耗）：

```bash
sudo sh -c '
  a=$(cat /sys/class/powercap/intel-rapl:0/energy_uj); sleep 3
  b=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
  echo $(( (b-a)/3000000 )) W
'
sudo powertop --time=30       # 观察 top offenders
sudo turbostat --summary --quiet --show PkgWatt,CorWatt,GFXWatt
sudo intel_gpu_top            # 看 Video 引擎，验证硬解
```

单项回滚：删除或注释 `modules/system/performance.nix` 中对应段落、`home/xfce.nix` 中的 DPMS 属性，
重新求值后由用户重建。

回滚：

```bash
sudo nixos-rebuild switch --rollback     # 回到上一个 generation
nixos-rebuild list-generations           # 查看全部 generation
# 无法登录时：重启，在 systemd-boot 菜单里选旧 generation 启动
```

### 音频

`modules/services/pipewire.nix` 只保留 48 kHz / 1024 frames 的时钟配置，**不再设置 USB DAC 的
`channelmix.max-volume`**。XFCE 音量滑块因此使用 PipeWire 原生范围（100% 对应 1.0，
默认上限 1.5），不会再在某个百分比后失效。

`home/audio.nix` 启用 Home Manager 的 `services.easyeffects`：

- 物理 USB DAC 仍是系统默认 sink；EasyEffects 用 `EffectsPipelines.processAllOutputs = true`
  把应用输出自动接到自己的虚拟 sink，**不把虚拟 sink 设为默认**（上游推荐做法，避免环路和路由混乱）。
- 启动时加载 output preset `Macmini`：只有一个 limiter，`threshold = -1.0` dBFS、
  `gain-boost = false`，只做峰值保护，不加 EQ/压缩/自动增益，不改变原有音色。
- 依赖系统已启用的 `programs.dconf`（见 `modules/desktop/remote.nix`）。

复核：

```bash
systemctl --user is-active easyeffects
journalctl --user -u easyeffects -b --no-pager | tail -30
wpctl status
wpctl inspect @DEFAULT_AUDIO_SINK@ | grep -E 'node.name|channelmix'
wpctl get-volume @DEFAULT_AUDIO_SINK@
ls ~/.local/share/easyeffects/output/Macmini.json
```

`channelmix` 里不应再出现 `max-volume = 0.216`；默认 sink 应仍是
`alsa_output.usb-Musical_Fidelity...`。把音量拉到 100% 以上
（`wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.2`）应能实际改变音量；`1.0` 是数字满刻度参考，
超过 100% 属于数字增益，limiter 只处理峰值，不替代功放音量。

排障/回退：

- EasyEffects 没起来：`systemctl --user start easyeffects`，再看 journal。
- 不想让 EE 处理所有输出：把 `EffectsPipelines.processAllOutputs` 改为 `false` 后重建，
  或临时 `systemctl --user stop easyeffects`。
- 完全回到旧行为：`sudo nixos-rebuild switch --rollback`，或 `git revert` 后重建。
- 本机没有安装 `pactl`；用 `wpctl` / `pavucontrol`，`pw-top` 可看音频图负载。

## 5. 调试工具箱

已随 `home/packages.nix` 安装：`nix-diff`、`nix-tree`、`nixfmt`、`deadnix`、`statix`、`nixd`、
`nix-output-monitor`（`nom`）、`direnv` + `nix-direnv`、`zellij`。
性能/功耗观测工具 `powertop`、`turbostat`、`cpupower`、`intel_gpu_top` 由
`modules/system/performance.nix` 安装。

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
  可把 `PasswordAuthentication` 改为 `false`（改 `modules/system/server.nix` 并重建）。
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
  包，版本号固定在 `hosts/Macmini/default.nix` 的 `permittedInsecurePackages` 中。升级内核后若求值报
  insecure 错误，需把新版本号加入该列表。Wi-Fi 由 `iwd` 后端 + NetworkManager 管理，
  用 `nmcli device wifi list` / `nmcli device wifi connect`。
- **视频硬解**：Haswell 仅支持 H.264，H.265/VP9 会走软解（见 `modules/desktop/bilibili.nix` 注释）。
- **home-manager 文件冲突**：已有同名文件会被重命名为 `*.backup`（`backupFileExtension = "backup"`），
  冲突时先看 `.backup` 再决定去留。
- **镜像**：`mirrors.enable = true`（mirrors-nix）会替换 substituter；若下载报 404/超时，
  检查 `/etc/nix/nix.conf` 的 `substituters`，必要时临时 `--option substituters https://cache.nixos.org`。
- **systemd-boot 只留 5 个 generation**：`configurationLimit = 5`，旧代会被清理，回滚要趁早。
- **启动菜单只停 1 秒**：`boot.loader.timeout = 1`；开机时按方向键/空格可停住菜单，需要固定菜单时改成 `3`。
- **DPMS 15 分钟熄屏**：由 `home/xfce.nix` 设置；看视频被误熄屏时调大 `dpms-on-ac-sleep/off` 或删除属性。
- **zram 不是磁盘 swap**：`swapon --show` 里 `/dev/zram0` 的大小是未压缩容量；内存吃紧时先看
  `zramctl` 的 DATA/COMPR，必要时把 `memoryPercent` 从 25 调到 50。
- **SATA ALPM 不可用**：Apple SSD/AHCI 对所有非 `max_performance` 策略写入返回 `EOPNOTSUPP`/`EINVAL`；
  不要再加 `link_power_management_policy` 的 udev 规则，保持默认即可。

## 9. 常用命令速查

```bash
ssh Macmini                                  # 登录
zellij attach                                # 接回持久会话
sudo nixos-rebuild switch --flake .#Macmini  # 重建（用户执行）
sudo nixos-rebuild switch --rollback         # 回滚
nix flake check                              # flake 健全性检查
nix eval --raw .#nixosConfigurations.Macmini.config.system.build.toplevel.drvPath
systemd-analyze                              # 启动耗时
zramctl; swapon --show                       # zram 状态
sudo powertop --time=30                      # 功耗/唤醒源
git -C /home/qanix/nixos-macmini71 status
git -C /home/qanix/nixos-macmini71 push origin main
```
