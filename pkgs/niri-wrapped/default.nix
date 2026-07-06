{
  self',
  niri,
  xwayland-satellite,
  bibata-cursors,
  wrapPackage,
  dev ? false,
}:
let
  config = if dev then "/home/soft/setup/pkgs/niri-wrapped/config.kdl" else ./config.kdl;

  path = [
    self'.packages.ghostty-wrapped
    self'.packages.fuzzel-wrapped
    self'.packages.volume-control
    self'.packages.brightness-control
    self'.packages.scale-floating-window
    xwayland-satellite
  ];
in
wrapPackage {
  package = niri;
  env.NIRI_CONFIG = "${config}";
  prefix.XCURSOR_PATH = "${bibata-cursors}/share/icons";

  runtimeInputs = path;
  inheritPath = true;
  # niri.service points at the unwrapped binary; patch it to use the wrapper.
  filesToPatch = [ "$out/share/systemd/user/niri.service" ];
  # Fail the build on an invalid config rather than at compositor start-up.
  checks = [ "${niri}/bin/niri validate --config ${./config.kdl}" ];
  # Required for niri to register as a session with the display manager.
  passthru.providedSessions = niri.passthru.providedSessions;
}
