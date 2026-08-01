{
  wrapPackage,
  noctalia,
  writeTextFile,
}:
let
  # A directory of plugins, scanned by a [[plugins.source]] of kind "path"
  # below. Keeping it a source root rather than symlinking into the data dir
  # means nothing has to be written to $HOME.
  plugins = ./plugins;

  # noctalia resolves its config directory as $NOCTALIA_CONFIG_HOME/noctalia
  # (src/util/file_utils.h, configDir()), so the store path we point at needs
  # that extra level inside it.
  configHome = writeTextFile {
    name = "noctalia-config-home";
    destination = "/noctalia/config.toml";

    text = /* toml */ ''
      [theme]
      builtin = "Catppuccin"

      # Plugins are opt-in by id, and declaring a source replaces the default
      # (which scans the data dir), so nothing outside the store is scanned.
      [plugins]
      enabled = [ "etrobert/weekday" ]

      [[plugins.source]]
      kind = "path"
      name = "setup"
      location = "${plugins}"

      [location]
      address = "Berlin"

      # Attached panels are drawn on the bar's own surface and inherit its
      # background_opacity (panel_manager.cpp: m_attachedBackgroundOpacity),
      # so a transparent bar makes the calendar and friends see-through and
      # unreadable over windows. Floating panels get their own surface, whose
      # opacity comes from transparency_mode instead — "solid" by default.
      # launcher, clipboard and polkit already float; these three did not.
      [shell.panel]
      control_center_placement = "floating"
      wallpaper_placement = "floating"
      session_placement = "floating"

      [bar.main]
      position = "left"
      scale = 1.2

      # Default 6, which leaves the twelve icons in `end` cramped. There is no
      # per-section setting — this widens `start` by the same amount, which the
      # clock stack can afford.
      widget_spacing = 12
      margin_opposite_edge = 5

      # Span the whole edge as waybar did. margin_ends defaults to 180, which
      # is what leaves the bar floating in the middle.
      margin_ends = 0

      # Show the wallpaper through the bar instead of the Surface fill. Only
      # half the job: noctalia also asks the compositor to blur behind the bar,
      # unconditionally and with no setting to stop it, so niri overrides that
      # with a layer-rule on the noctalia-bar-main namespace.
      background_opacity = 0.0
      shadow = false

      start = [ "clock", "etrobert/weekday:bar", "date" ]
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
      vertical_format = "{:%H %M %S}"

      [widget.date]
      format = "{:%d %m %y}"

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
