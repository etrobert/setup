{
  self,
  wrapFirefox,
  firefox-unwrapped,
  lib,
}:
let
  browserConfig = import (self + /lib/browser-config.nix) { inherit lib; };
in
wrapFirefox firefox-unwrapped {
  extraPrefs = ''
    ${browserConfig.renderDefaultPrefs browserConfig.sharedSettings}
  '';
  extraPolicies = browserConfig.sharedPolicies;
}
