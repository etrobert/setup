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

  # Fail the build on a broken config rather than at shell start-up.
  #
  # `config validate` has no --strict flag and is weaker than its --help
  # claims: it exits non-zero *only* on TOML syntax errors. A misspelled key
  # is downgraded to `WARN … unknown setting`, and a bad value is either
  # `WARN … unknown value` or, for plenty of keys, reported not at all — a
  # wrong `bar.main.position` produces no output whatsoever. So promote every
  # warning to a build failure, and accept that bad *values* on unvalidated
  # keys still get through.
  checks = [
    ''
      report=$(${noctalia}/bin/noctalia config validate ${configHome}/noctalia 2>&1) || {
        echo "$report" >&2
        exit 1
      }
      echo "$report"
      if grep -qE '^\s*WARN' <<<"$report"; then
        echo "error: noctalia rejected part of this config (see warnings above)" >&2
        exit 1
      fi
    ''
  ];
}
