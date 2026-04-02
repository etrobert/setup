{
  self',
  symlinkJoin,
  makeWrapper,
  lib,
  waybar,
  dev ? false,
}:
let
  path = "/home/soft/setup/nix/pkgs/waybar-wrapped";
  config = if dev then path + "/config.jsonc" else ./config.jsonc;
  style = if dev then path + "/style.css" else ./style.css;
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
      --prefix PATH : ${lib.makeBinPath [ self'.packages.get-weather ]}
  '';
}
