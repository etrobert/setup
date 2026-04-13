{
  inputs',
  wrapFirefox,
  lib,
}:
let
  browserConfig = import ../../browser-config.nix { inherit lib; };
in
wrapFirefox inputs'.zen-browser.packages.zen-browser-unwrapped {
  extraPrefs = ''
    ${browserConfig.renderDefaultPrefs (
      browserConfig.sharedSettings
      // {
        "zen.theme.content-element-separation" = 4;
        "zen.theme.border-radius" = 12;
      }
    )}
  '';
  extraPolicies = browserConfig.sharedPolicies;
}
