{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };

      makeFirefox =
        extraSettings:
        pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPrefs = browserConfig.renderDefaultPrefs (browserConfig.sharedSettings // extraSettings);
          extraPolicies = browserConfig.sharedPolicies;
        };
    in
    {
      packages = {
        firefox-wrapped = makeFirefox { };

        # Hardware AV1 decode is broken on the i915 iGPU; software decode of the
        # same streams pins the CPU, so turn AV1 off there instead.
        firefox-wrapped-no-av1 = makeFirefox { "media.av1.enabled" = false; };
      };
    };
}
