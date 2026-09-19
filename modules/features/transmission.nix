# c411's seeding rule: 72 h or ratio 1.0 per torrent
# (https://c411.org/wiki/ratio-seedtime). The reaper removes torrents that
# met it, files included; tower has copied them long before (torrent-pull.nix).
let
  seedSeconds = 72 * 3600;
  # A torrent can hit ratio 1.0 minutes after finishing, before the next pull.
  graceSeconds = 3600;
in
{
  flake.nixosModules.transmission =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      transmission-reaper = pkgs.writeShellApplication {
        name = "transmission-reaper";

        runtimeInputs = [
          config.services.transmission.package
          pkgs.jq
        ];

        inheritPath = false;

        text = /* bash */ ''
          transmission-remote --json -t all -i |
            jq --raw-output --argjson min ${toString seedSeconds} --argjson grace ${toString graceSeconds} '
              .result.torrents[]
              | select(
                  .percent_done == 1
                  and .done_date <= (now - $grace)
                  and (.seconds_seeding >= $min or .upload_ratio >= 1)
                )
              | "\(.hash_string) \(.name)"
            ' |
            while read -r hash name; do
              echo "removing $name"
              transmission-remote -t "$hash" --remove-and-delete
            done
        '';
      };
    in
    {
      services.transmission = {
        enable = true;

        # A VPS has no NAT: incoming peers land directly, so the port is
        # public on purpose. The RPC/web UI stays on loopback, behind tsnsrv.
        openPeerPorts = true;

        # The Host header tsnsrv forwards is the tailnet name.
        settings.rpc-host-whitelist = "torrents";
      };

      services.tsnsrv.services.torrents.toURL =
        "http://127.0.0.1:${toString config.services.transmission.settings.rpc-port}";

      # /var/lib/transmission is 750: the group is how tower's pull reads
      # Downloads/.
      users.users.soft.extraGroups = [ config.services.transmission.group ];

      systemd.services.transmission-reaper = {
        description = "Remove torrents that met the seeding rule";
        after = [ "transmission.service" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe transmission-reaper;
          DynamicUser = true;
        };
      };

      systemd.timers.transmission-reaper = {
        description = "Schedule the transmission reaper";
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = "hourly";
      };
    };
}
