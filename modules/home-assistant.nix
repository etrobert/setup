_: {
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "hue"
      "led_ble"
      "ibeacon"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      homeassistant = {
        auth_providers = [
          {
            type = "trusted_networks";
            trusted_networks = [
              "192.168.0.0/24"
              "100.64.0.0/10"
            ];
            allow_bypass_login = true;
          }
          { type = "homeassistant"; }
        ];
      };
    };
  };
}
