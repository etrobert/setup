{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      inputs',
      ...
    }:
    {
      # The zen-browser input has no darwin outputs, so this cannot be built there.
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        zen-browser-wrapped = lib.makeOverridable (
          {
            extraSettings ? { },
          }:
          let
            browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };
          in
          pkgs.wrapFirefox inputs'.zen-browser.packages.zen-browser-unwrapped {
            extraPrefs = browserConfig.renderDefaultPrefs (
              browserConfig.sharedSettings
              // {
                "zen.theme.content-element-separation" = 4;
                "zen.theme.border-radius" = 12;
              }
              // extraSettings
            );
            extraPolicies = browserConfig.sharedPolicies;
          }
        ) { };
      };
    };
}
