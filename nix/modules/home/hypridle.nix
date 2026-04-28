_: {
  flake.homeModules.hypridle = {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
        };
        listener = [
          {
            timeout = 300; # 5 minutes
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 900; # 15 minutes
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
