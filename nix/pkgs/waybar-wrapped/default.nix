{
  self',
  symlinkJoin,
  makeWrapper,
  lib,
  waybar,
  jq,
  coreutils,
  gawk,
  pavucontrol,
  dev ? false,
}:
let
  path = "/home/soft/setup/nix/pkgs/waybar-wrapped";
  config = if dev then path + "/config.jsonc" else ./config.jsonc;
  style = if dev then path + "/style.css" else ./style.css;
  runtimeDeps = lib.makeBinPath [
    coreutils
    self'.packages.get-weather
    jq # used by custom/weekday and custom/cpu-governor
    gawk # used by custom/cpu-freq
    pavucontrol
  ];
in
symlinkJoin {
  name = "waybar-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ waybar ];
  meta.mainProgram = "waybar";
  postBuild = ''
    wrapProgram $out/bin/waybar \
      --add-flags "--config ${config}" \
      --add-flags "--style ${style}" \
      --set PATH ${runtimeDeps}
  '';
}
