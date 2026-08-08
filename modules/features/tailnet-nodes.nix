# Give local services their own MagicDNS names by running an extra Tailscale
# node per service, so Home Assistant is `home/` rather than `tower:8123`.
#
# Each entry runs its own userspace-networking tailscaled with a private state
# directory and control socket, joins the tailnet under the given hostname, and
# proxies `https://<name>.tailcab4c0.ts.net` to a local port with a
# Tailscale-issued certificate. The names resolve on the tailnet only, at home
# and away — nothing is published to the LAN or the WAN.
#
# Unlike Tailscale Services this needs no tag on the host and no tailnet policy
# changes: each node is an ordinary device joining with the existing auth key.
_: {
  flake.nixosModules.tailnetNodes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.tailnetNodes;

      tailscaled = lib.getExe' config.services.tailscale.package "tailscaled";
      tailscale = lib.getExe config.services.tailscale.package;

      socketPath = name: "/run/tailnet-${name}/tailscaled.sock";

      # Each node needs its own UDP port for direct connections; without one the
      # firewall forces its peers onto a DERP relay, which would put Immich
      # uploads over a round trip through Frankfurt. 41641 is the host daemon's.
      nodes = lib.imap0 (index: name: {
        inherit name;
        localPort = cfg.${name};
        wireguardPort = 41642 + index;
      }) (lib.attrNames cfg);

      # `tailscale status` exits non-zero while logged out, which is the only
      # time the auth key is needed — re-running `up` on every boot would fail
      # once the key expires, taking working nodes down with it.
      configure =
        node:
        pkgs.writeShellScript "tailnet-node-${node.name}-configure" ''
          set -e
          ts() { ${tailscale} --socket=${socketPath node.name} "$@"; }

          ts status >/dev/null 2>&1 \
            || ts up --auth-key "file:${config.age.secrets.tailscale-authkey.path}" --hostname=${node.name}

          ts serve --bg --https=443 http://localhost:${toString node.localPort}
        '';
    in
    {
      options.services.tailnetNodes = lib.mkOption {
        type = lib.types.attrsOf lib.types.port;
        default = { };

        example = {
          home = 8123;
          photos = 2283;
        };

        description = ''
          Local ports to publish on the tailnet, keyed by the MagicDNS name each
          should answer to. Every name becomes a separate device in the tailnet.
        '';
      };

      config = lib.mkIf (cfg != { }) {
        networking.firewall.allowedUDPPorts = map (node: node.wireguardPort) nodes;

        systemd.services = lib.listToAttrs (
          map (
            node:
            lib.nameValuePair "tailnet-node-${node.name}" {
              description = "Tailnet node ${node.name}, serving localhost:${toString node.localPort}";
              wants = [ "network-online.target" ];
              after = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "notify";

                ExecStart = lib.concatStringsSep " " [
                  tailscaled
                  "--tun=userspace-networking"
                  "--socket=${socketPath node.name}"
                  "--statedir=/var/lib/tailnet-${node.name}"
                  "--port=${toString node.wireguardPort}"
                ];

                ExecStartPost = configure node;
                RuntimeDirectory = "tailnet-${node.name}";
                StateDirectory = "tailnet-${node.name}";
                StateDirectoryMode = "0700";
                Restart = "on-failure";
              };
            }
          ) nodes
        );
      };
    };
}
