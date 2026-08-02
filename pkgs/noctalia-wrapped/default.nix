{
  wrapPackage,
  noctalia,
  runCommand,
  ddcutil,
  coreutils,
}:
let
  plugins = ./plugins;

  configHome = runCommand "noctalia-config-home" { } ''
    mkdir -p $out/noctalia
    substitute ${./config.toml} $out/noctalia/config.toml \
      --replace-fail '@plugins@' '${plugins}'
  '';

  # Without --skip-ddc-checks, every ddcutil invocation re-runs a full display
  # detect, which dominates a brightness change: 0.50s vs 0.05s on the U3223QE.
  # noctalia builds its ddcutil argv in C++, so the flag is injected via PATH.
  fast-ddcutil = wrapPackage {
    package = ddcutil;
    flags = [ "--skip-ddc-checks" ];

    # ddcutil shells out to uname; wrapPackage otherwise leaves it an empty PATH.
    runtimeInputs = [ coreutils ];
  };
in
wrapPackage {
  package = noctalia;

  env.NOCTALIA_CONFIG_HOME = configHome;

  # The brightness service shells out to ddcutil, and the wrapper clears PATH.
  runtimeInputs = [ fast-ddcutil ];

  checks = [ "${noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
}
