{ lib }:
{
  renderDefaultPrefs =
    settings:
    builtins.concatStringsSep "\n" (
      map (name: "defaultPref(${lib.strings.toJSON name}, ${lib.strings.toJSON settings.${name}});") (
        builtins.attrNames settings
      )
    );

  sharedPolicies = {
    PasswordManagerEnabled = false;
    DontCheckDefaultBrowser = true;
    SearchEngines = {
      Default = "DuckDuckGo";
    };
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
        default_area = "menupanel";
      };
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        installation_mode = "force_installed";
        default_area = "navbar";
      };
      "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
        installation_mode = "force_installed";
        default_area = "menupanel";
      };
    };
  };

  sharedSettings = {
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
  };
}
