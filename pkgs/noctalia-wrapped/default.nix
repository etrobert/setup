{
  wrapPackage,
  noctalia,
  applyPatches,
  runCommand,
  ddcutil,
  coreutils,
  bitwarden-cli,
  official-plugins,
  community-plugins,
}:
let
  plugins = ./plugins;

  wallpaper = ../../assets/saint-levant.jpg;

  # nix-monitor only re-reads the remote revision, generation list and store
  # sizes on its poll timers, so a `switch` leaves the widget claiming an
  # update is available for up to an hour. The patch keys that refresh off the
  # local revision instead, which the service already polls every 10s.
  # `patch` fails the build if upstream reworks the same code.
  patched-community-plugins = applyPatches {
    name = "noctalia-community-plugins-patched";
    src = community-plugins;
    patches = [ ./nix-monitor-recheck-on-generation-change.patch ];
  };

  configHome = runCommand "noctalia-config-home" { } ''
    mkdir -p $out/noctalia
    substitute ${./config.toml} $out/noctalia/config.toml \
      --replace-fail '@plugins@' '${plugins}' \
      --replace-fail '@official-plugins@' '${official-plugins}' \
      --replace-fail '@community-plugins@' '${patched-community-plugins}' \
      --replace-fail '@wallpaper@' '${wallpaper}'
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

  # The launcher resolves desktop-entry Exec= against noctalia's own PATH.
  inheritPath = true;

  runtimeInputs = [
    fast-ddcutil
    bitwarden-cli
  ];

  checks = [ "${noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
}
