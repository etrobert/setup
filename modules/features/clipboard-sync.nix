{ self, ... }:
{
  flake.nixosModules.clipboard-sync =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      peers = lib.attrNames (
        lib.filterAttrs (
          name: host: name != config.networking.hostName && host.config.systemd.user.services ? clipboard-sync
        ) self.nixosConfigurations
      );

      clipboard-receive = pkgs.writeShellApplication {
        name = "clipboard-receive";
        inheritPath = false;
        runtimeInputs = [
          pkgs.coreutils
          pkgs.wl-clipboard
        ];
        text = /* bash */ ''
          received=$XDG_RUNTIME_DIR/clipboard-sync-received
          cat >"$received"

          # wl-copy stays in the background holding its output, which keeps the SSH session open.
          wl-copy <"$received" >/dev/null 2>&1
        '';
      };

      clipboard-send = pkgs.writeShellApplication {
        name = "clipboard-send";
        inheritPath = false;
        runtimeInputs = [
          pkgs.coreutils
          pkgs.diffutils
          pkgs.openssh
        ];
        text = /* bash */ ''
          received=$XDG_RUNTIME_DIR/clipboard-sync-received
          new=$(mktemp)
          trap 'rm "$new"' EXIT
          cat >"$new"

          # An emptied clipboard arrives as no data.
          [ -s "$new" ] || exit 0

          # Sending back what a peer sent lets two simultaneous copies swap forever.
          cmp --silent "$new" "$received" && exit 0
          rm --force "$received"

          # An array, because shellcheck rejects a loop over a single literal (SC2043).
          peers=(${lib.escapeShellArgs peers})
          for peer in "''${peers[@]}"; do
            # ConnectTimeout: a sleeping peer would otherwise stall every later copy.
            ssh -o ConnectTimeout=2 "$peer" clipboard-receive <"$new" || true
          done
        '';
      };
    in
    {
      environment.systemPackages = [ clipboard-receive ];

      systemd.user.services.clipboard-sync = {
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe clipboard-send}";
      };
    };
}
