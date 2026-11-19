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

      clipboard-send = pkgs.writeShellApplication {
        name = "clipboard-send";
        inheritPath = false;
        runtimeInputs = with pkgs; [
          coreutils
          diffutils
          openssh
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

          # shellcheck disable=SC2043 # the peers are generated, and may be a single host
          for peer in ${lib.escapeShellArgs peers}; do
            # ConnectTimeout: a sleeping peer would otherwise stall every later copy.
            # wl-copy stays in the background holding stderr, which keeps the SSH session open.
            # shellcheck disable=SC2016 # $XDG_RUNTIME_DIR expands on the peer
            ssh -o ConnectTimeout=2 "$peer" 'tee "$XDG_RUNTIME_DIR/clipboard-sync-received" | wl-copy 2>/dev/null' <"$new" || true
          done
        '';
      };
    in
    {
      systemd.user.services.clipboard-sync = {
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe clipboard-send}";
      };
    };
}
