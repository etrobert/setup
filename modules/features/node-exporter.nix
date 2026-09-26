# Scraped by Prometheus over the tailnet (metrics.nix).
_: {
  flake.nixosModules.node-exporter =
    { config, ... }:
    {
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        config.services.prometheus.exporters.node.port
      ];
    };
}
