{
  pkgs,
  pronto,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 10d";
  };

  environment.systemPackages = with pkgs; [
    pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
    bat
    btop
    difftastic
    entr
    eza
    fd
    fzf
    gh
    git
    htop
    jq
    magic-wormhole
    neovim
    nixfmt
    ripgrep
    shellcheck
    shfmt
    stow
    tmux
    (writeShellApplication {
      name = "tmux-sessionizer";
      runtimeInputs = [
        coreutils
        gnused
        tmux
        fzf
        findutils
      ];
      text = builtins.readFile ../../tmux/.local/bin/tmux-sessionizer;
    })
    unzip
    vim
    wget
    zsh-autosuggestions # Fish shell autosuggestions for Zsh
    zsh-syntax-highlighting
  ];

  programs.zsh.enable = true;
  # Disable system compinit; we call compinit -u in .zshrc to skip
  # insecure directory warnings caused by Nix store paths.
  programs.zsh.enableGlobalCompInit = false;

  # Symlink zsh-syntax-highlighting to /run/current-system/sw/share/ (not included by default)
  environment.pathsToLink = [ "/share/zsh-syntax-highlighting" ];
}
