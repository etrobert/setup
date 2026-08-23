{
  self',
  lib,
  niri,
  nirius,
  fetchFromSourcehut,
  rustPlatform,
  xwayland-satellite,
  bibata-cursors,
  wrapPackage,
  dev ? false,
}:
let
  config = if dev then "/home/soft/work/setup/main/pkgs/niri-wrapped/config.kdl" else ./config.kdl;

  # toggle-follow-mode --policy needs 0.9.0, not in nixpkgs yet; the assertion
  # fails the build once it is, prompting removal of this override.
  nirius-0-9-0 =
    assert lib.assertMsg (lib.versionOlder nirius.version "0.9.0")
      "nixpkgs now has nirius ${nirius.version} — drop the override in pkgs/niri-wrapped/default.nix";
    nirius.overrideAttrs (_: rec {
      version = "0.9.0";

      src = fetchFromSourcehut {
        owner = "~tsdh";
        repo = "nirius";
        rev = "nirius-${version}";
        hash = "sha256-GWbmX+x4X0VXb9kgpu1rS30hWK5MAuvGBp48MQfnS8w=";
      };

      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit src;
        name = "nirius-${version}-vendor";
        hash = "sha256-RDDbx/JiyWwPOBEJDl7uJ1rGvGK1IYnjv0UTNjg+Yhc=";
      };
    });

  path = [
    self'.packages.ghostty-wrapped
    self'.packages.noctalia-wrapped
    self'.packages.scale-floating-window
    nirius-0-9-0
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
