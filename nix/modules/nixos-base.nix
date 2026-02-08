{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];

  system.activationScripts.nixos-symlink.text = ''
    ln --symbolic --force --no-dereference /home/soft/setup/nix /etc/nixos
  '';

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

  nix.gc.dates = "daily";

  nix.settings.auto-optimise-store = true;

  zramSwap.enable = true;

  age.secrets.tailscale-authkey.file = ../secrets/tailscale-authkey.age;

  services = {
    # Configure keymap in X11
    xserver.xkb = {
      layout = "us";
      variant = "";
      options = "ctrl:nocaps";
    };

    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale-authkey.path;
    };

    openssh.enable = true;
  };

  users.users.soft = {
    isNormalUser = true;
    description = "Etienne";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
