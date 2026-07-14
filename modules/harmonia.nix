_: {
  flake.nixosModules.harmonia =
    { config, ... }:
    {
      age.secrets.harmonia-signing-key.file = ../secrets/harmonia-signing-key.age;

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.harmonia-signing-key.path ];
      };

      # Not WAN-reachable: the router only forwards 80/443 to tower.
      networking.firewall.allowedTCPPorts = [ 5000 ];
    };
}
