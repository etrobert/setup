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
      [bar.main]
      position = "left"

      # awww owns the wallpaper; without this noctalia draws its own on top.
      [wallpaper]
      enabled = false
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
