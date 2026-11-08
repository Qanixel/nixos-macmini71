{ pkgs, lib, ... }:

{
  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  # mkAfter：固定放在各模块自动加入的包之后，保证合并顺序与重构前一致。
  home.packages = lib.mkAfter (with pkgs; [
    # 如下是我常用的一些命令行工具，你可以根据自己的需要进行增删
    fastfetch
    nnn # terminal file manager
    yazi
    bat
    lsd

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # Nix 调试 / 开发工具
    nix-diff # 对比两个 derivation 的构建输入差异
    nix-tree # 交互式浏览 store 路径的依赖树与闭包大小
    nixfmt # 官方 Nix 代码格式化（RFC 166 风格）
    deadnix # 查找未使用的 let 绑定 / 函数参数
    statix # Nix 代码 lint（反模式检查）
    nixd # Nix language server（VS Code / neovim 补全与跳转）

    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    usbutils # lsusb

    # 终端复用：远程会话断线后可 attach 恢复（配合 modules/system/debug.nix 的 linger）
    zellij

    # some software
    # xxx
    splayer-next
  ]);
}
