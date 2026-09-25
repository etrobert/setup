# Scraped by charon's Prometheus over the tailnet (metrics.nix).
_: {
  flake.nixosModules.smartctlExporter =
    { config, ... }:
    {
      # Autodiscovers every disk. Labels drives `sda`-style, matching
      # node_exporter's, so temperature joins against disk I/O directly.
      services.prometheus.exporters.smartctl.enable = true;

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        config.services.prometheus.exporters.smartctl.port
      ];
    };
}
