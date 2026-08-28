{
  self,
  wrapFirefox,
  firefox-unwrapped,
  lib,
  extraSettings ? { },
}:
let
  browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };
in
wrapFirefox firefox-unwrapped {
  extraPrefs = browserConfig.renderDefaultPrefs (browserConfig.sharedSettings // extraSettings);
  extraPolicies = browserConfig.sharedPolicies;
}
