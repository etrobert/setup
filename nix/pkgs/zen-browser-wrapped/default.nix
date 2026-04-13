{ inputs', wrapFirefox }:
let
  browserConfig = import ../../browser-config.nix;
in
wrapFirefox inputs'.zen-browser.packages.zen-browser-unwrapped {
  extraPrefs = /* javascript */ ''
    ${browserConfig.renderDefaultPrefs (
      browserConfig.sharedSettings
      // {
        "zen.theme.content-element-separation" = 4;
        "zen.theme.border-radius" = 12;
      }
    )}
  '';
  extraPolicies = browserConfig.sharedPolicies // {
    DontCheckDefaultBrowser = true;
  };
}
