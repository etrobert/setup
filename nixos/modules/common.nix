{ pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable I2C for ddcutil (external monitor brightness)
  hardware.i2c.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.graphics.enable = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

  programs.zsh.enable = true;

  programs.firefox = {
    enable = true;
    policies = {
      PasswordManagerEnabled = false;
    };
  };

  users.users.soft = {
    isNormalUser = true;
    description = "Etienne";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../pronto.nix { })
    adwaita-icon-theme # includes cursor theme
    bash-language-server
    bat
    btop
    claude-code
    ddcutil
    difftastic
    eza
    fd
    fzf
    gcc
    gh
    ghostty
    git
    gnumake
    grim
    heroic
    slurp
    hyprpaper
    jq
    libnotify # exposes notify-send
    lua-language-server
    mako # notifications daemon
    neovim
    nixd
    nixfmt
    nodejs_latest
    opencode
    pavucontrol
    playerctl
    prettierd
    ripgrep
    shfmt
    spotify
    stow
    stylua
    tmux
    typescript-language-server
    vim
    waybar
    wget
    wl-clipboard
    wofi
    zsh
  ];

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  programs.hyprland.enable = true;

  services.openssh.enable = true;
}
