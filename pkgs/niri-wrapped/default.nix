{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = self.lib.onlySupported rec {
        niri-wrapped = lib.makeOverridable (
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
          }
        ) { };
        niri-wrapped-dev = niri-wrapped.override { dev = true; };
      };
    };
}
