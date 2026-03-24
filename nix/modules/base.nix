{
  pkgs,
  ...
}:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 10d";
  };

  environment.systemPackages = with pkgs; [
    bat
    btop
    coreutils
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
    (symlinkJoin {
      name = "neovim-wrapped";
      buildInputs = [ makeWrapper ];
      paths = [ neovim ];
      postBuild = ''
        wrapProgram $out/bin/nvim \
          --prefix PATH : ${lib.makeBinPath [ shfmt ]}
      '';
    })
    nixfmt
    ripgrep
    shellcheck
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

  age.secrets.tailscale-authkey.file = ../secrets/tailscale-authkey.age;

  programs.ssh.knownHosts = {
    pi = {
      hostNames = [ "pi" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbTCtRJeFqky1PSKe45KI0aMhpKqgd32Z9Fy9S4Op89";
    };
  };

  programs.zsh = {
    enable = true;
    # Disable system compinit; we call compinit -u in .zshrc to skip
    # insecure directory warnings caused by Nix store paths.
    enableGlobalCompInit = false;
  };

  # Symlink zsh-syntax-highlighting to /run/current-system/sw/share/ (not included by default)
  environment.pathsToLink = [ "/share/zsh-syntax-highlighting" ];
}
