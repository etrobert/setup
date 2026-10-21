{ inputs, ... }:
{
  flake.nixosModules.rift-radar =
    { config, ... }:
    {
      imports = [ inputs.rift-radar.nixosModules.default ];

      services.rift-radar = {
        enable = true;
        hostName = "rift.etiennerobert.com";
        # The upstream option still takes an agenix secret: `.path` to read, `.file` to restart on.
        riotKey = {
          inherit (config.sops.templates.riot-api-key) path;
          file = config.sops.secrets.riot-api-key.sopsFile;
        };
      };

      sops.secrets.riot-api-key.sopsFile = ../../secrets/charon.yaml;
      sops.templates.riot-api-key.content = "RIOT_API_KEY=${config.sops.placeholder.riot-api-key}\n";
    };
}
