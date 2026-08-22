# Prometheus scrapes tower's node exporter; Grafana reads it back.
# Reached on the tailnet as `metrics/` (see tailnet-services.nix).
{ inputs, ... }:
{
  flake.nixosModules.metrics =
    { config, pkgs, ... }:
    let
      # Grafana provisions from a directory, not a file.
      dashboards = pkgs.runCommand "grafana-dashboards" { } ''
        mkdir $out
        cp ${inputs.node-exporter-dashboard} $out/node-exporter-full.json
      '';
    in
    {
      services = {
        prometheus = {
          enable = true;

          exporters.node.enable = true;

          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [
                { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
              ];
            }
          ];
        };

        grafana = {
          enable = true;

          settings = {
            # Encrypts credentials in Grafana's DB, of which we store none. Move
            # this to agenix *before* adding any datasource that needs one:
            # rotating the key once the DB holds secrets has no supported path.
            security.secret_key = "SW2YcwTIb9zpOOhoPsMm";

            # The tailnet is the boundary, as it is for comfy/.
            "auth.anonymous" = {
              enabled = true;

              # Viewer would do for dashboards, but Explore needs Editor.
              org_role = "Editor";
            };

            auth.disable_login_form = true;

            server = {
              # 3000 is creatures, 3001 is umami.
              http_port = 3002;

              # Without this Grafana redirects to its own listen address.
              root_url = "http://metrics/";
            };
          };

          provision.dashboards.settings.providers = [
            { options.path = dashboards; }
          ];

          provision.datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              isDefault = true;
            }
          ];
        };
      };
    };
}
