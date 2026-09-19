_: {
  flake.nixosModules.transmission =
    { config, ... }:
    {
      services.transmission = {
        enable = true;

        # A VPS has no NAT: incoming peers land directly, so the port is
        # public on purpose. The RPC/web UI stays on the tailnet.
        openPeerPorts = true;

        settings = {
          rpc-bind-address = "0.0.0.0";
          # Only tailscale0 reaches 9091 (below), so the IP whitelist would
          # just restate the firewall; its syntax has no CIDR anyway.
          rpc-whitelist-enabled = false;
          rpc-host-whitelist = "charon";
        };
      };

      # /var/lib/transmission is 750: the group is how tower's pull reads
      # Downloads/.
      users.users.soft.extraGroups = [ config.services.transmission.group ];

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        config.services.transmission.settings.rpc-port
      ];
    };
}
