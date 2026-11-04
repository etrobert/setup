_: {
  flake.nixosModules.harmonia =
    { config, ... }:
    {
      age.secrets.harmonia-signing-key.file = ../../secrets/harmonia-signing-key.age;

      ports.harmonia = 5000;

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.harmonia-signing-key.path ];
        settings.bind = "[::]:${toString config.ports.harmonia}";
      };

      networking.firewall.allowedTCPPorts = [ config.ports.harmonia ];
    };
}
