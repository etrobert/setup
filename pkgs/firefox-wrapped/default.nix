{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.firefox-wrapped = lib.makeOverridable (
        {
          extraSettings ? { },
        }:
        let
          browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };
        in
        pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPrefs = browserConfig.renderDefaultPrefs (browserConfig.sharedSettings // extraSettings);
          extraPolicies = browserConfig.sharedPolicies;
        }
      ) { };
    };
}
