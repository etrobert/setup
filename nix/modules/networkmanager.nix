_: {
  flake.nixosModules.networkmanager = {
    networking.networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [
          "/run/agenix/wifi-soft"
          "/run/agenix/wifi-iphone-de-zeus"
        ];
        profiles.soft = {
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
        profiles.iphoneDeZeus = {
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
      };
    };
  };
}
