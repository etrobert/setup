_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        lock-suspend = pkgs.writeShellApplication {
          name = "lock-suspend";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = [
            pkgs.coreutils # sleep
            pkgs.systemd
          ];
          inheritPath = false;
          text = ''
            loginctl lock-session
            sleep 1
            systemctl suspend
          '';
        };
      };
    };
}
