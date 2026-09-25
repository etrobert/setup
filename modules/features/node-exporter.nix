# Scraped by charon's Prometheus over the tailnet (metrics.nix).
_: {
  flake.nixosModules.nodeExporter =
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
