_: {
  flake.nixosModules.prometheusGrafana =
    { config, pkgs, ... }:
    let
      inherit (config.services.prometheus) exporters;
    in
    {
      # The four SATA SSDs expose no temperature to hwmon until drivetemp
      # binds them.
      boot.kernelModules = [ "drivetemp" ];

      age.secrets.grafana-secret-key = {
        file = ../../secrets/grafana-secret-key.age;
        owner = "grafana";
      };

      services = {
        prometheus = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9090;
          retentionTime = "90d";

          exporters = {
            node = {
              enable = true;
              listenAddress = "127.0.0.1";

              enabledCollectors = [
                "diskstats"
                "hwmon"
                "zfs"
              ];
            };

            smartctl = {
              enable = true;
              listenAddress = "127.0.0.1";
            };
          };

          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [ { targets = [ "127.0.0.1:${toString exporters.node.port}" ]; } ];
            }

            {
              job_name = "smartctl";
              static_configs = [ { targets = [ "127.0.0.1:${toString exporters.smartctl.port}" ]; } ];
            }
          ];
        };

        grafana = {
          enable = true;

          settings = {
            server = {
              http_addr = "127.0.0.1";
              # 3000, 3001 and 3003 are already taken on tower.
              http_port = 3010;
            };

            security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
          };

          provision = {
            enable = true;

            datasources.settings.datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                uid = "prometheus";
                url = "http://127.0.0.1:${toString config.services.prometheus.port}";
                isDefault = true;
              }
            ];

            dashboards.settings.providers = [
              {
                name = "disks";

                options.path = pkgs.linkFarm "grafana-dashboards" {
                  "disks.json" = ./prometheus-grafana-disks.json;
                };
              }
            ];
          };
        };
      };
    };
}
