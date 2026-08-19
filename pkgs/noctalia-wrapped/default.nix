{
  lib,
  wrapPackage,
  noctalia,
  runCommand,
  ddcutil,
  coreutils,
  bitwarden-cli,
  official-plugins,
  community-plugins,
  # Hosts whose GPU exposes no VRAM stat (e.g. an i915 iGPU) would render the
  # widget permanently empty; noctalia has no hide-when-unavailable option.
  withVramWidget ? true,
}:
let
  plugins = ./plugins;

  wallpaper = ../../assets/saint-levant.jpg;

  configHome = runCommand "noctalia-config-home" { } ''
    mkdir -p $out/noctalia
    substitute ${./config.toml} $out/noctalia/config.toml \
      --replace-fail '@plugins@' '${plugins}' \
      --replace-fail '@official-plugins@' '${official-plugins}' \
      --replace-fail '@community-plugins@' '${community-plugins}' \
      --replace-fail '@wallpaper@' '${wallpaper}' \
      --replace-fail '@vram-widget@' '${lib.optionalString withVramWidget ''"vram",''}'
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
