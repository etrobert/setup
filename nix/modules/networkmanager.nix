_: {
  flake.nixosModules.networkmanager = {
    networking.networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [
          "/run/agenix/wifi-soft"
          "/run/agenix/wifi-iphone-de-zeus"
          "/run/agenix/wifi-vinni"
        ];

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

    age.secrets = {
      wifi-soft.file = ../secrets/wifi-soft.age;
      wifi-iphone-de-zeus.file = ../secrets/wifi-iphone-de-zeus.age;
      wifi-vinni.file = ../secrets/wifi-vinni.age;
    };
  };
}
