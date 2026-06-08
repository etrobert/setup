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
    # Air Quality dashboard for the AirGradient ONE in the living room.
    # Rendered to ui-lovelace.yaml and registered as an extra sidebar
    # dashboard below — does not replace the auto-generated Overview.
    lovelaceConfig = {
      title = "Air Quality";
      views = [
        {
          title = "Air Quality";
          path = "air-quality";
          icon = "mdi:air-filter";
          # Panel view with a single vertical-stack so cards flow top to
          # bottom at full width in a fixed order, instead of the default
          # masonry layout auto-splitting them into uneven columns.
          type = "panel";
          cards = [
            {
              type = "vertical-stack";
              cards = [
                {
                  type = "horizontal-stack";
                  cards = [
                    {
                      type = "gauge";
                      entity = "sensor.i_9psl_carbon_dioxide";
                      name = "CO₂";
                      unit = "ppm";
                      min = 400;
                      max = 2000;
                      needle = true;
                      # ppm: <800 fresh, 800-1000 stuffy, >1000 ventilate
                      severity = {
                        green = 400;
                        yellow = 800;
                        red = 1000;
                      };
                    }
                    {
                      type = "gauge";
                      entity = "sensor.i_9psl_pm2_5";
                      name = "PM2.5";
                      min = 0;
                      max = 100;
                      needle = true;
                      # µg/m³: WHO 24h guideline ~15, EPA sensitive ~35
                      severity = {
                        green = 0;
                        yellow = 12;
                        red = 35;
                      };
                    }
                    {
                      type = "gauge";
                      entity = "sensor.i_9psl_temperature";
                      name = "Temp";
                      min = 10;
                      max = 35;
                      needle = true;
                    }
                    {
                      type = "gauge";
                      entity = "sensor.i_9psl_humidity";
                      name = "Humidity";
                      min = 0;
                      max = 100;
                      needle = true;
                    }
                  ];
                }
                {
                  type = "history-graph";
                  title = "CO₂ (24h)";
                  hours_to_show = 24;
                  entities = [ { entity = "sensor.i_9psl_carbon_dioxide"; } ];
                }
                {
                  type = "history-graph";
                  title = "Particulate Matter";
                  hours_to_show = 24;
                  entities = [
                    { entity = "sensor.i_9psl_pm1"; }
                    { entity = "sensor.i_9psl_pm2_5"; }
                    { entity = "sensor.i_9psl_pm10"; }
                  ];
                }
                {
                  type = "history-graph";
                  title = "Temperature & Humidity";
                  hours_to_show = 24;
                  entities = [
                    { entity = "sensor.i_9psl_temperature"; }
                    { entity = "sensor.i_9psl_humidity"; }
                  ];
                }
                {
                  type = "history-graph";
                  title = "VOC & NOx Index";
                  hours_to_show = 24;
                  entities = [
                    { entity = "sensor.i_9psl_voc_index"; }
                    { entity = "sensor.i_9psl_nox_index"; }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      # Title the NixOS-managed lovelaceConfig dashboard (defaults to
      # "Overview") and show it in the sidebar as "Air Quality".
      lovelace.dashboards.nixos-lovelace = {
        mode = "yaml";
        filename = "ui-lovelace.yaml";
        title = "Air Quality";
        icon = "mdi:air-filter";
        show_in_sidebar = true;
      };
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
        {
          id = "co2_air_the_room";
          alias = "Air Quality - Notify to air the room";
          description = "Notify when CO2 stays above 1000 ppm for 10 minutes.";
          trigger = [
            {
              platform = "numeric_state";
              entity_id = "sensor.i_9psl_carbon_dioxide";
              above = 1000;
              for = {
                minutes = 10;
              };
            }
          ];
          action = [
            {
              service = "notify.all_devices";
              data = {
                title = "Air the room 🪟";
                message = "CO₂ is {{ states('sensor.i_9psl_carbon_dioxide') }} ppm — open a window.";
              };
            }
          ];
          mode = "single";
        }
      ];
      # Notification targets. `all_devices` fans a notification out to the
      # phone (Companion app) and the self-hosted ntfy bus, which the desktops
      # (tower/leod/aaron) subscribe to — see modules/ntfy.nix. Automations
      # notify `notify.all_devices` so every alert reaches all surfaces.
      notify = [
        {
          # Publish to the ntfy `home` topic. HA runs on tower alongside the
          # ntfy server, so it posts to localhost. POST_JSON to the ntfy root
          # URL sends `{message, title, topic}` — ntfy's JSON publish format —
          # so this works as a real notify service and can join a group below.
          platform = "rest";
          name = "ntfy_home";
          resource = "http://localhost:2586";
          method = "POST_JSON";
          message_param_name = "message";
          title_param_name = "title";
          data = {
            topic = "home";
          };
        }
        {
          platform = "group";
          name = "all_devices";
          services = [
            { service = "mobile_app_soft_phone"; }
            { service = "ntfy_home"; }
          ];
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
