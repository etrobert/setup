{
  wrapPackage,
  noctalia,
  runCommand,
}:
let
  # A directory of plugins, scanned by a [[plugins.source]] of kind "path" in
  # config.toml. Keeping it a source root rather than symlinking into the data
  # dir means nothing has to be written to $HOME.
  plugins = ./plugins;

  # noctalia resolves its config directory as $NOCTALIA_CONFIG_HOME/noctalia
  # (src/util/file_utils.h, configDir()), so the store path we point at needs
  # that extra level inside it.
  configHome = runCommand "noctalia-config-home" { } ''
    mkdir -p $out/noctalia
    substitute ${./config.toml} $out/noctalia/config.toml \
      --replace-fail '@plugins@' '${plugins}'
  '';
in
wrapPackage {
  package = noctalia;

  # Baking the config read-only costs nothing here: v5 reads the config dir but
  # writes UI changes to the state dir instead (~/.local/state/noctalia/
  # settings.toml), which it overlays on top of this. So the settings UI keeps
  # working, and anything changed there wins over what is set in config.toml.
  env.NOCTALIA_CONFIG_HOME = configHome;

  # Catches TOML syntax errors at build time rather than at shell start-up.
  # Only those: noctalia downgrades a misspelled key to a warning, and reports
  # a bad value for some keys — bar.main.position included — not at all.
  checks = [ "${noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
}
