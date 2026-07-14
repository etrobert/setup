_: {
  flake.nixosModules.harmonia =
    { config, ... }:
    {
      age.secrets.harmonia-signing-key.file = ../secrets/harmonia-signing-key.age;

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.harmonia-signing-key.path ];
        # The nixpkgs module defaults this to 50; 30 beats cache.nixos.org
        # (40) so consumers prefer tower and pull at LAN speed.
        settings.priority = 30;
      };

      # Not WAN-reachable: the router only forwards 80/443 to tower.
      networking.firewall.allowedTCPPorts = [ 5000 ];
    };
}
