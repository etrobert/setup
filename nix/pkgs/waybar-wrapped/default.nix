{
  self',
  lib,
  pkgs,
  dev ? false,
}:
let
  path = "/home/soft/setup/nix/pkgs/waybar-wrapped";
  config = if dev then path + "/config.jsonc" else ./config.jsonc;
  style = if dev then path + "/style.css" else ./style.css;
  runtimeDeps = with pkgs; [
    coreutils
    self'.packages.get-weather
    jq # used by custom/weekday and custom/cpu-governor
    gawk # used by custom/cpu-freq
    pavucontrol
  ];
in
pkgs.symlinkJoin {
  name = "waybar-wrapped";
  nativeBuildInputs = with pkgs; [ makeWrapper ];
  paths = with pkgs; [ waybar ];
  meta.mainProgram = "waybar";
  postBuild = ''
    wrapProgram $out/bin/waybar \
      --add-flags "--config ${config}" \
      --add-flags "--style ${style}" \
      --set PATH ${lib.makeBinPath runtimeDeps}
  '';
}
