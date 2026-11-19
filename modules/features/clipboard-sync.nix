_: {
  flake.nixosModules.clipboard-sync =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
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

          # Sending back what the peer sent lets two simultaneous copies swap forever.
          cmp --silent "$new" "$received" && exit 0
          rm --force "$received"

          # ConnectTimeout: a sleeping peer would otherwise stall every later copy.
          ssh -o ConnectTimeout=2${config.clipboardSync.peer} clipboard-receive <"$new"
        '';
      };
    in
    {
      options.clipboardSync.peer = lib.mkOption {
        type = lib.types.str;
        description = "Host that shares its clipboard with this one.";
      };

      config = {
        environment.systemPackages = [ clipboard-receive ];

        systemd.user.services.clipboard-sync = {
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe clipboard-send}";
        };
      };
    };
}
