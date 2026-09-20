{ inputs, ... }:
{
  flake.nixosModules.riftRadar =
    { config, ... }:
    {
      imports = [ inputs.rift-radar.nixosModules.default ];

      services.rift-radar = {
        enable = true;
        hostName = "rift.etiennerobert.com";
        riotKey = config.age.secrets.riot-api-key;
      };

      age.secrets.riot-api-key.file = ../../secrets/riot-api-key.age;
    };
}
