_: {
  # nix-darwin has no services.syncthing module, so we just run syncthing as a
  # launchd user agent. Its devices/folders are configured through the GUI
  # (reachable over Tailscale at :8384) and persisted in syncthing's own config
  # — unlike the NixOS hosts, which declare the peer/folder list in
  # lib/syncthing-settings.nix via services.syncthing.
  flake.darwinModules.syncthing =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [ pkgs.syncthing ];

      launchd.user.agents.syncthing.serviceConfig = {
        ProgramArguments = [
          (lib.getExe pkgs.syncthing)
          "serve"
          "--no-browser"
          "--no-upgrade" # the nix-store binary must not replace itself
          "--gui-address=0.0.0.0:8384"
        ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
}
