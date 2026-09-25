# Prometheus scrapes every host's exporters; Grafana reads it back.
# Runs on charon: always on, so pi and charon keep history while tower is off.
# Reached on the tailnet as `metrics/` through tsnsrv.
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

          # Drive wear and disk-usage trends are the point of collecting this,
          # and both move over years. ~2 GB/year at the current 2.4k series.
          retentionTime = "5y";

          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [
                {
                  # Every host importing nodeExporter, on its default port.
                  targets = map (host: "${host}:9100") [
                    "tower"
                    "charon"
                    "pi"
                  ];
                }
              ];
            }
            {
              job_name = "smartctl";
              static_configs = [
                # tower imports smartctlExporter, on its default port.
                { targets = [ "tower:9633" ]; }
              ];
            }

            # Its own health — WAL corruption, failed compactions, on-disk
            # growth against the 5y retention above — is otherwise readable
            # only by hand off /metrics, never as history.
            {
              job_name = "prometheus";
              static_configs = [
                { targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ]; }
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

            # The tailnet is the boundary.
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

        tsnsrv.services.metrics.toURL = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      };
    };
}
