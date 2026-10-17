_: {
  flake.nixosModules.harmonia =
    { config, ... }:
    {
      age.secrets.harmonia-signing-key.file = ../../secrets/harmonia-signing-key.age;

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.harmonia-signing-key.path ];
      };

      networking.firewall.allowedTCPPorts = [ 5000 ];
    };
}
