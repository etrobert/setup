_: {
  flake.nixosModules.networkmanager =
    { config, ... }:
    {
      networking.networkmanager = {
        enable = true;
        ensureProfiles = {
          environmentFiles = [ config.sops.templates.wifi-passwords.path ];

          profiles = {
            soft = {
              connection = {
                id = "soft";
                type = "wifi";
              };
              wifi = {
                ssid = "soft";
                mode = "infrastructure";
              };
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WIFI_PASSWORD";
              };
            };

            iphoneDeZeus = {
              connection = {
                id = "iPhone de Zeus";
                type = "wifi";
              };
              wifi = {
                ssid = "iPhone de Zeus";
                mode = "infrastructure";
              };
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WIFI_PASSWORD_IPHONE_DE_ZEUS";
              };
            };

            vinni = {
              connection = {
                id = "Vodafone-150C";
                type = "wifi";
              };
              wifi = {
                ssid = "Vodafone-150C";
                mode = "infrastructure";
              };
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WIFI_PASSWORD_VINNI";
              };
            };
          };
        };
      };

      sops.secrets = {
        wifi-soft.sopsFile = ../../secrets/linux-workstations.yaml;
        wifi-iphone-de-zeus.sopsFile = ../../secrets/linux-workstations.yaml;
        wifi-vinni.sopsFile = ../../secrets/linux-workstations.yaml;
      };

      sops.templates.wifi-passwords.content = ''
        WIFI_PASSWORD=${config.sops.placeholder.wifi-soft}
        WIFI_PASSWORD_IPHONE_DE_ZEUS=${config.sops.placeholder.wifi-iphone-de-zeus}
        WIFI_PASSWORD_VINNI=${config.sops.placeholder.wifi-vinni}
      '';
    };
}
