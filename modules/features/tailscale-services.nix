# Give local services their own MagicDNS names on the tailnet, so Home Assistant
# is `home/` rather than `tower:8123`.
#
# Each entry becomes a Tailscale Service: its own virtual IP and MagicDNS name
# (`<name>.tailcab4c0.ts.net`, or bare `<name>` via the MagicDNS search domain),
# terminating HTTPS with a Tailscale-issued certificate and proxying to a local
# port. The names resolve on the tailnet only, at home and away — nothing is
# published to the LAN or the WAN.
#
# Only the host half is declared here. The services themselves, the grants that
# allow access, and the tag this node advertises them under are tailnet state and
# live in the tailnet policy file:
#
#   "tagOwners":     { "tag:server": ["autogroup:admin"] }
#   "grants":        [ { "src": ["*"], "dst": ["svc:home"], "ip": ["*"] } ]
#   "autoApprovers": { "services": { "svc:home": ["tag:server"] } }
#
# tailscaled-autoconnect only sends the auth key when the backend state is
# NeedsLogin/NeedsMachineAuth/Stopped, so a tag applied to an already-running
# node survives reboots and rebuilds.
_: {
  flake.nixosModules.tailscaleServices =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.tailscaleServices;

      # `serve set-config` derives both the inbound listener and the proxy scheme
      # from one field, so it can only terminate TLS when the local service also
      # speaks it (cmd/tailscale/cli/serve_v2.go). Home Assistant and Immich
      # speak plain HTTP, so the per-service CLI form is the only one that fits.
      # An empty config still prunes declaratively: `serve reset` drops handlers
      # but leaves the advertisement behind in prefs.
      emptyConfig = (pkgs.formats.json { }).generate "tailscale-serve-empty.json" {
        version = "0.0.1";
        services = { };
      };

      serveCommand =
        name: port: "tailscale serve --service=svc:${name} --https=443 http://localhost:${toString port}";
    in
    {
      options.services.tailscaleServices = lib.mkOption {
        type = lib.types.attrsOf lib.types.port;
        default = { };

        example = {
          home = 8123;
          photos = 2283;
        };

        description = ''
          Local ports to publish as Tailscale Services, keyed by the MagicDNS
          name each should answer to. Each name must also exist in the tailnet
          policy file — see the comment at the top of this file.
        '';
      };

      config = lib.mkIf (cfg != { }) {
        # `serve` terminates TLS inside tailscaled and delivers over the tailnet
        # interface, so the port is opened there and nowhere else.
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 443 ];

        systemd.services.tailscale-services = {
          description = "Publish local services on the tailnet";
          after = [ "tailscaled-autoconnect.service" ];
          wants = [ "tailscaled-autoconnect.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [ config.services.tailscale.package ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            tailscale serve set-config --all ${emptyConfig}
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList serveCommand cfg)}
          '';
        };
      };
    };
}
