# Self-hosted ntfy notification server, reachable only over Tailscale (the
# port is opened on tailscale0 only — never the LAN or WAN). Machines on the
# tailnet publish to topics here and subscribe to receive desktop
# notifications. The Linux desktop subscriber lives in
# modules/nixos-workstation.nix.
_: {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://tower:2586";
      listen-http = ":2586";
    };
  };

  # Expose ntfy to the tailnet only. Within the tailnet topics are open (no
  # auth), which is acceptable for personal use.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2586 ];
}
