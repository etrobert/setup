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
      --add-flags "--config ${./config.jsonc}" \
      --add-flags "--style ${./style.css}" \
      --prefix PATH : ${lib.makeBinPath [ self'.packages.get-weather ]}
  '';
}
