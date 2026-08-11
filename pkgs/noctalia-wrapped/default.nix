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

  # sysmon labels VRAM only as a percentage, so it reads unlike ram right next
  # to it on the bar. The patch adds the bytes-valued stat ram already has.
  #
  # The guard runs in prePatch because the patch introduces the very string it
  # looks for: seeing gpu_vram_used in the pristine source means upstream has
  # shipped its own, and this should go.
  patched-noctalia = noctalia.overrideAttrs (previous: {
    patches = (previous.patches or [ ]) ++ [ ./gpu-vram-used-stat.patch ];

    prePatch = (previous.prePatch or "") + /* bash */ ''
      if grep -q 'gpu_vram_used' src/shell/bar/widgets/sysmon_widget_definition.cpp; then
        echo "noctalia ships gpu_vram_used now; drop gpu-vram-used-stat.patch" >&2
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
