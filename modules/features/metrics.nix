# Prometheus scrapes every host's exporters; Grafana reads it back.
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

      # Fires for each series of `expr` that `evaluator` matches.
      alert =
        {
          uid,
          title,
          expr,
          evaluator,
          for,
        }:
        {
          inherit uid title for;
          condition = "B";
          data = [
            {
              refId = "A";
              datasourceUid = "prometheus";
              relativeTimeRange = {
                from = 600;
                to = 0;
              };
              model = {
                inherit expr;
                instant = true;
              };
            }
            {
              refId = "B";
              datasourceUid = "__expr__";
              model = {
                type = "threshold";
                expression = "A";
                conditions = [ { inherit evaluator; } ];
              };
            }
          ];
        };
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

          provision = {
            dashboards.settings.providers = [
              { options.path = dashboards; }
            ];

            datasources.settings.datasources = [
              {
                name = "Prometheus";
                uid = "prometheus";
                type = "prometheus";
                url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                isDefault = true;
              }
            ];

            # Failed units and disk health already alert on their own, through
            # ntfyFailureAlerts, ZED and smartd.
            alerting = {
              contactPoints.settings.contactPoints = [
                {
                  name = "ntfy";
                  receivers = [
                    {
                      uid = "ntfy";
                      type = "webhook";
                      # ntfy's built-in template turns Grafana's payload into a title and message.
                      settings.url = "http://ntfy/home?template=grafana";
                    }
                  ];
                }
              ];

              policies.settings.policies = [ { receiver = "ntfy"; } ];

              rules.settings.groups = [
                {
                  name = "hosts";
                  folder = "Alerts";
                  interval = "1m";
                  rules = [
                    (alert {
                      uid = "disk-full";
                      title = "Disk over 85% full";
                      # /nix/store is a bind mount of /, which would alert twice.
                      expr = ''100 * (1 - node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs",mountpoint!="/nix/store"} / node_filesystem_size_bytes)'';
                      evaluator = {
                        type = "gt";
                        params = [ 85 ];
                      };
                      for = "10m";
                    })
                    (alert {
                      uid = "oom-kill";
                      title = "OOM kill";
                      expr = "increase(node_vmstat_oom_kill[1h])";
                      evaluator = {
                        type = "gt";
                        params = [ 0 ];
                      };
                      for = "0s";
                    })
                    (alert {
                      uid = "host-down";
                      title = "Host down";
                      # tower is turned off every night on purpose.
                      expr = ''up{instance!~"tower:.*"}'';
                      evaluator = {
                        type = "lt";
                        params = [ 1 ];
                      };
                      for = "5m";
                    })
                  ];
                }
              ];
            };
          };
        };

        tsnsrv.services.metrics.toURL = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      };
    };
}
