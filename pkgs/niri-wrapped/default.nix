{ self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages =
        let
          makeNiriWrapped =
            {
              dev ? false,
            }:
            let
              config = if dev then "/home/soft/work/setup/main/pkgs/niri-wrapped/config.kdl" else ./config.kdl;

              path = [
                self'.packages.ghostty-wrapped
                self'.packages.noctalia-wrapped
                self'.packages.scale-floating-window
                pkgs.nirius
                pkgs.xwayland-satellite
              ];
            in
            pkgs.wrapPackage {
              package = pkgs.niri;
              env.NIRI_CONFIG = "${config}";
              prefix.XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";

              runtimeInputs = path;
              inheritPath = true;
              # niri.service points at the unwrapped binary; patch it to use the wrapper.
              filesToPatch = [ "$out/share/systemd/user/niri.service" ];
              # Fail the build on an invalid config rather than at compositor start-up.
              checks = [ "${pkgs.niri}/bin/niri validate --config ${./config.kdl}" ];
              # Required for niri to register as a session with the display manager.
              passthru.providedSessions = pkgs.niri.passthru.providedSessions;
            };
        in
        self.lib.onlySupported {
          niri-wrapped = makeNiriWrapped { };
          niri-wrapped-dev = makeNiriWrapped { dev = true; };
        };
    };

  flake.nixosModules.niri =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) niri-wrapped niri-wrapped-dev;
    in
    {
      options.wrappers.niri = {
        liveConfig = lib.mkEnableOption ''
          reading config.kdl from the working copy at /home/soft/work/setup/main
          instead of the store, so edits apply on reload without a rebuild. niri
          falls back to its built-in defaults if that path is absent
        '';

        wrapper = lib.mkOption {
          type = lib.types.package;
          default = if config.wrappers.niri.liveConfig then niri-wrapped-dev else niri-wrapped;
        };
      };
    };
}
