{ inputs, ... }:
{
  flake.nixosModules.taskgraph =
    { config, ... }:
    {
      imports = [ inputs.taskgraph.nixosModules.default ];

      ports.taskgraph = "auto";

      services = {
        taskgraph = {
          enable = true;
          port = config.ports.taskgraph;
        };

        caddy.virtualHosts."graph.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:${toString config.services.taskgraph.port}
        '';
      };
    };
}
