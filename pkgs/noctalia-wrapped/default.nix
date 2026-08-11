{
  wrapPackage,
  noctalia,
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

  # sysmon can only label VRAM as a percentage, so it reads unlike ram right
  # next to it on the bar. The guard fires once upstream grows a bytes-valued
  # VRAM stat, since the patch is then the wrong way to get one.
  patched-noctalia = noctalia.overrideAttrs (previous: {
    patches = (previous.patches or [ ]) ++ [ ./vram-gib.patch ];

    postPatch = (previous.postPatch or "") + /* bash */ ''
      if grep -rq 'gpu_vram_used' src/shell/bar/widget_factory.cpp; then
        echo "noctalia now ships a bytes VRAM stat; drop vram-gib.patch and set stat = \"gpu_vram_used\"" >&2
        exit 1
      fi
    '';
  });

  configHome = runCommand "noctalia-config-home" { } ''
    mkdir -p $out/noctalia
    substitute ${./config.toml} $out/noctalia/config.toml \
      --replace-fail '@plugins@' '${plugins}' \
      --replace-fail '@official-plugins@' '${official-plugins}' \
      --replace-fail '@community-plugins@' '${community-plugins}' \
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
  package = patched-noctalia;

  env.NOCTALIA_CONFIG_HOME = configHome;

  # The launcher resolves desktop-entry Exec= against noctalia's own PATH.
  inheritPath = true;

  runtimeInputs = [
    fast-ddcutil
    bitwarden-cli
  ];

  checks = [ "${patched-noctalia}/bin/noctalia config validate ${configHome}/noctalia" ];
}
