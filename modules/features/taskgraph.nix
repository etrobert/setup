{ inputs, self, ... }:
{
  flake.nixosModules.taskgraph =
    { config, ... }:
    {
      imports = [ inputs.taskgraph.nixosModules.default ];

      services = {
        taskgraph = {
          enable = true;
          port = self.lib.portFor "taskgraph";
        };

        caddy.virtualHosts."graph.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:${toString config.services.taskgraph.port}
        '';
      };
    };
}
