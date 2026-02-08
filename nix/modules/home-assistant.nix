_: {
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "hue_ble"
      "led_ble"
      "ibeacon"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
    };
  };
}
