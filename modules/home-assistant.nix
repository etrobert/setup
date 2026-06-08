_: {
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "hue"
      "led_ble"
      "ibeacon"
      "airgradient"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      input_boolean = {
        auto_brightness = {
          name = "Auto Brightness";
          icon = "mdi:brightness-auto";
        };
      };
      automation = [
        {
          id = "circadian_lighting";
          alias = "Circadian Lighting - Adjust lights throughout day";
          description = "Gradually adjusts all lights based on time of day for circadian rhythm";
          trigger = [
            {
              platform = "time_pattern";
              minutes = "/15";
            }
            {
              platform = "homeassistant";
              event = "start";
            }
            {
              platform = "state";
              entity_id = "input_boolean.auto_brightness";
              to = "on";
            }
          ];
          condition = [
            {
              condition = "state";
              entity_id = "light.home";
              state = "on";
            }
            {
              condition = "state";
              entity_id = "input_boolean.auto_brightness";
              state = "on";
            }
          ];
          action = [
            {
              variables = {
                min_time = 16;
                max_time = 23;
                offset_time = 5;
                min_brightness = 64;
                max_brightness = 255;
                min_color_temp_kelvin = 2000;
                max_color_temp_kelvin = 4000;
              };
            }
            {
              service = "light.turn_on";
              target.entity_id = "light.home";
              data = {
                brightness = /* jinja */ ''
                  {% set time = now().hour + (now().minute / 60.0) %}
                  {% set adjusted_time = (time - offset_time) % 24 %}
                  {% set clamped = [min_time - offset_time, [adjusted_time, max_time - offset_time] | min] | max %}
                  {% set normalized = (clamped - (min_time - offset_time)) / ((max_time - offset_time) - (min_time - offset_time)) %}
                  {{ (min_brightness + ((1 - normalized) * (max_brightness - min_brightness))) | int }}
                '';
                color_temp_kelvin = /* jinja */ ''
                  {% set time = now().hour + (now().minute / 60.0) %}
                  {% set adjusted_time = (time - offset_time) % 24 %}
                  {% set clamped = [min_time - offset_time, [adjusted_time, max_time - offset_time] | min] | max %}
                  {% set normalized = (clamped - (min_time - offset_time)) / ((max_time - offset_time) - (min_time - offset_time)) %}
                  {{ (min_color_temp_kelvin + ((1 - normalized) * (max_color_temp_kelvin - min_color_temp_kelvin))) | int }}
                '';
                transition = 5;
              };
            }
          ];
          mode = "restart";
        }
      ];
      homeassistant = {
        auth_providers = [
          {
            type = "trusted_networks";
            trusted_networks = [
              "127.0.0.1/32"
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
