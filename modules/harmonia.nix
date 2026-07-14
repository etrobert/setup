_: {
  flake.nixosModules.harmonia =
    { config, ... }:
    {
      age.secrets.harmonia-signing-key.file = ../secrets/harmonia-signing-key.age;

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.harmonia-signing-key.path ];
        # Prefer cache.nixos.org (priority 40) over this cache.
        settings.priority = 50;
      };

      # Not WAN-reachable: the router only forwards 80/443 to tower.
      networking.firewall.allowedTCPPorts = [ 5000 ];
    };
}
