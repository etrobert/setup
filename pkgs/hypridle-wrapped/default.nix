{
  self',
  writeTextDir,
  hypridle,
  procps,
  systemd,
  wrapPackage,
}:
let
  config = writeTextDir "hypr/hypridle.conf" /* hyprlang */ ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
    }

    listener {
        timeout = 300
        on-timeout = loginctl lock-session
    }

    listener {
        timeout = 900
        on-timeout = systemctl suspend
    }
  '';
in
wrapPackage {
  package = hypridle;
  env.XDG_CONFIG_HOME = "${config}";

  runtimeInputs = [
    procps # pidof
    systemd # loginctl, systemctl
    self'.packages.hyprlock-wrapped # hyprlock
  ];
}
