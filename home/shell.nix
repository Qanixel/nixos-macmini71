{ pkgs, ... }:

{
  # 所有 shell 共享的别名（bash / zsh / fish 都会生效）
  home.shellAliases = {
    nu = "sudo nixos-rebuild switch --flake /home/qanix/nixos-macmini71#Macmini";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      k = "kubectl";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "lsd";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "robbyrussell";
    };
  };

  programs.fish = {
    enable = true;
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    ];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # zellij：终端复用器。默认不自动接管新终端，手动 `zellij` 启动，
  # 断线重连后 `zellij attach` 恢复；会话由 linger 保活。
  programs.zellij = {
    enable = true;
  };

  # direnv + nix-direnv：进入含 .envrc（use flake）的目录自动加载开发环境
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
