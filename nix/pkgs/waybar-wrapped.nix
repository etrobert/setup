{
  self',
  symlinkJoin,
  makeWrapper,
  lib,
  waybar,
}:
symlinkJoin {
  name = "waybar-wrapped";
  buildInputs = [ makeWrapper ];
  paths = [ waybar ];
  meta.mainProgram = "waybar";
  postBuild = ''
    wrapProgram $out/bin/waybar \
      --add-flags "--config ${../../waybar/.config/waybar/config.jsonc}" \
      --add-flags "--style ${../../waybar/.config/waybar/style.css}" \
      --prefix PATH : ${lib.makeBinPath [ self'.packages.get-weather ]}
  '';
}
