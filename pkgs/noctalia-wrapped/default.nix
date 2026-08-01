{
  wrapPackage,
  noctalia,
  writeTextFile,
}:
let
  # noctalia resolves its config directory as $NOCTALIA_CONFIG_HOME/noctalia
  # (src/util/file_utils.h, configDir()), so the store path we point at needs
  # that extra level inside it.
  configHome = writeTextFile {
    name = "noctalia-config-home";
    destination = "/noctalia/config.toml";

    text = /* toml */ ''
      [theme]
      builtin = "Catppuccin"

      [location]
      address = "Berlin"

      [bar.main]
      position = "left"
      scale = 1.2
      margin_opposite_edge = 5
      start = [ "clock" ]
      center = []
      end = [
          "media",
          "tray",
          "notifications",
          "clipboard",
          "network",
          "bluetooth",
          "volume",
          "brightness",
          "battery",
          "control-center",
          "workspaces",
          "session"
      ]

      # awww owns the wallpaper; without this noctalia draws its own on top.
      [wallpaper]
      enabled = false

      # A vertical bar uses vertical_format, so stack the lines the way waybar
      # did: hour/minute/second, weekday, day/month/year. \n is escaped by
      # TOML, not by Nix — an indented Nix string passes the backslash through.
      #
      # waybar cut the weekday to two letters via `date +%a | cut -c1-2`. There
      # is no equivalent here: %a is three letters, and no noctalia bar widget
      # can run a command — text and custom_button both take static strings.
      [widget.clock]
      vertical_format = "{:%H\n%M\n%S\n%a\n%d\n%m\n%y}"
      tooltip_format = "{:%A, %B %d, %Y}"

      [widget.brightness]
      show_label = false

      [widget.network]
      show_label = false

      [widget.volume]
      show_label = false
    '';
  };
in
wrapPackage {
  package = noctalia;

  # Baking the config read-only costs nothing here: v5 reads the config dir but
  # writes UI changes to the state dir instead (~/.local/state/noctalia/
  # settings.toml), which it overlays on top of this. So the settings UI keeps
  # working, and anything changed there wins over what is set above.
  env.NOCTALIA_CONFIG_HOME = configHome;

  # Catches TOML syntax errors at build time rather than at shell start-up.
  # Only those: noctalia downgrades a misspelled key to a warning, and reports
  # a bad value for some keys — bar.main.position included — not at all.
  checks = [ "${noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
}
