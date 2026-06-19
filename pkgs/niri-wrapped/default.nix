{
  self',
  niri,
  xwayland-satellite,
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
  env.NIRI_CONFIG = config;
  runtimeInputs = path;
  # niri.service references the unwrapped binary; patch it to use the wrapper.
  filesToPatch = [ "$out/share/systemd/user/*.service" ];
  passthru.providedSessions = niri.passthru.providedSessions;
  postBuild = ''
    ${niri}/bin/niri validate --config ${./config.kdl}
  '';
}
