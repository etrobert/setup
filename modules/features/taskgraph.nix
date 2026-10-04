{ inputs, ... }:
{
  flake.nixosModules.taskgraph =
    { config, ... }:
    {
      imports = [ inputs.taskgraph.nixosModules.default ];

      services = {
        taskgraph = {
          enable = true;
          # 3000 to 3003 are already taken on tower.
          port = 3004;
        };

        caddy.virtualHosts."graph.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:${toString config.services.taskgraph.port}
        '';
      };
    };
}
