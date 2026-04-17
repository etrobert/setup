# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tower";

  services.ddclient = {
    enable = true;
    protocol = "namecheap";
    server = "dynamicdns.park-your-domain.com";
    username = "etiennerobert.com";
    passwordFile = config.age.secrets.ddclient-password-etiennerobert-com.path;
    domains = [ "test" ];
    interval = "5min";
    usev6 = "no";
    usev4 = "webv4";
  };

  age.secrets.ddclient-password-etiennerobert-com.file = ../../../secrets/ddclient-password-etiennerobert-com.age;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    virtualHosts."test.etiennerobert.com".extraConfig = ''
      respond "hello from tower" 200
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
