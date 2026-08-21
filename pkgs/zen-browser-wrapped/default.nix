{
  self,
  inputs',
  wrapFirefox,
  lib,
  symlinkJoin,
  makeWrapper,
  writeShellApplication,
  coreutils,
  gawk,
  jq,
  mozlz4a,
  extraSettings ? { },
}:
let
  browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };

  applySpaceRouting = writeShellApplication {
    name = "zen-apply-space-routing";

    runtimeInputs = [
      coreutils
      gawk
      jq
      mozlz4a
    ];

    inheritPath = false;
    text = builtins.readFile ./apply-space-routing;
  };

  zen = wrapFirefox inputs'.zen-browser.packages.zen-browser-unwrapped {
    extraPrefs = browserConfig.renderDefaultPrefs (
      browserConfig.sharedSettings
      // {
        "zen.theme.content-element-separation" = 4;
        "zen.theme.border-radius" = 12;
      }
      // extraSettings
    );

    extraPolicies = browserConfig.sharedPolicies;
  };
in
# Space routing lives in the profile, not in prefs or policies, so it is applied
# on the way into the browser instead of being baked into the wrapper.
symlinkJoin {
  name = "zen-browser-wrapped";
  paths = [ zen ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    rm "$out/bin/zen"

    makeWrapper "${zen}/bin/zen" "$out/bin/zen" \
      --run '${lib.getExe applySpaceRouting} ${./space-routing.json} || true'
  '';
}
