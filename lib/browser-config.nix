{ lib }:
{
  renderDefaultPrefs =
    settings:
    lib.concatLines (
      lib.mapAttrsToList (
        name: value: "lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});"
      ) settings
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

  sharedChromeExtraOpts = {
    ExtensionInstallForcelist = [
      "bfbogjkneaangbdaafblgfnbpaapmnlb;https://clients2.google.com/service/update2/crx"
    ];
  };

  sharedSettings = {
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
    # Render at integer scale and let the compositor downscale. Firefox's own
    # Wayland fractional scaling triggers a popup-grab bug under Niri where
    # right-click menus and extension popups stop opening after a while, until
    # the browser is restarted (https://bugzilla.mozilla.org/show_bug.cgi?id=1849109).
    "widget.wayland.fractional-scale.enabled" = false;
  };
}
