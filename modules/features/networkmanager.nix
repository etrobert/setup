_: {
  flake.nixosModules.networkmanager =
    { config, ... }:
    {
      networking.networkmanager = {
        enable = true;
        ensureProfiles = {
          environmentFiles = [ config.age.secrets.wifi.path ];

          profiles = {
            soft = {
              connection = {
                id = "soft";
                type = "wifi";
              };
              wifi.ssid = "soft";
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WIFI_PSK_SOFT";
              };
            };

            iphoneDeZeus = {
              connection = {
                id = "iPhone de Zeus";
                type = "wifi";
              };
              wifi.ssid = "iPhone de Zeus";
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WIFI_PSK_IPHONE_DE_ZEUS";
              };
            };

            vinni = {
              connection = {
                id = "Vodafone-150C";
                type = "wifi";
              };
              wifi.ssid = "Vodafone-150C";
              wifi-security = {
                key-mgmt = "wpa-psk";
                psk = "$WIFI_PSK_VINNI";
              };
            };
          };
        };
      };

      age.secrets.wifi.file = ../../secrets/wifi.age;
    };
}
