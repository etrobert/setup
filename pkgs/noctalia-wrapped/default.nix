{
  wrapPackage,
  noctalia,
  runCommand,
}:
let
  plugins = ./plugins;

  configHome = runCommand "noctalia-config-home" { } ''
    mkdir -p $out/noctalia
    substitute ${./config.toml} $out/noctalia/config.toml \
      --replace-fail '@plugins@' '${plugins}'
  '';
in
wrapPackage {
  package = noctalia;

  env.NOCTALIA_CONFIG_HOME = configHome;

  checks = [ "${noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
}
