{
  flake.nixosModules.transmission-tunnel =
    { config, pkgs, ... }:
    {
      # Fixed: c411 reaches it by number.
      ports.transmission = 9091;

      systemd.services.transmission-tunnel = {
        description = "Forward a local port to the download host's transmission";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          # ControlPath=none: soft's ssh config shares connections, which hands the forward to another and exits
          # ExitOnForwardFailure: a port already taken must fail the unit, not leave ssh idling
          # ServerAliveInterval: a dead link must end ssh so systemd reconnects
          ExecStart = ''
            ${pkgs.openssh}/bin/ssh -N -o ControlPath=none -o ExitOnForwardFailure=yes \
              -o ServerAliveInterval=30 \
              -L 127.0.0.1:${toString config.ports.transmission}:127.0.0.1:9091 soft@51.91.29.38
          '';
          Restart = "always";
          RestartSec = "10s";
          # soft: the key the download host accepts.
          User = "soft";
          Environment = "HOME=/home/soft";
        };
      };
    };
}
