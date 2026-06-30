{
  hyprlock,
  coreutils,
  writeText,
  wrapPackage,
}:
let
  config = writeText "hyprlock.conf" /* hyprlang */ ''
    general {
      hide_cursor = true
    }

    background {
      path = screenshot
      blur_passes = 3
    }

    input-field {
      size = 200, 50
      outer_color = rgb(cdd6f4)
      inner_color = rgb(1e1e2e)
      font_color = rgb(cdd6f4)
      placeholder_text =
      position = 0, -40
    }

    label {
      text = $TIME
      font_family = FiraCode Nerd Font SemBd
      color = rgb(cdd6f4)
      font_size = 124
      position = 0, 80
    }

    label {
      text = cmd[update:60000] date "+%a %d/%m"
      font_family = FiraCode Nerd Font SemBd
      color = rgb(cdd6f4)
      font_size = 24
      position = 0, 180
    }

    label {
      text = $FPRINTPROMPT
      font_family = FiraCode Nerd Font SemBd
      color = rgb(cdd6f4)
      font_size = 14
      position = 0, -100
    }

    label {
      text = cmd[update:60000] /run/current-system/sw/bin/birthdays
      font_family = FiraCode Nerd Font SemBd
      color = rgb(cdd6f4)
      font_size = 24
      position = 0, -200
    }
  '';
in
wrapPackage {
  package = hyprlock;
  flags = [ "--config ${config}" ];
  runtimeInputs = [ coreutils ]; # date
}
