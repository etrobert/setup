{
  symlinkJoin,
  makeWrapper,
  hyprpaper,
  writeText,
}:
let
  config = writeText "hyprpaper.conf" /* hyprlang */ ''
    wallpaper {
        monitor =
        path = ${../../assets/saint-levant.jpg}
        fit_mode = cover
    }

    splash = false
  '';
in
symlinkJoin {
  name = "hyprpaper-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ hyprpaper ];
  meta.mainProgram = "hyprpaper";
  postBuild = ''
    wrapProgram $out/bin/hyprpaper \
      --add-flags "-c ${config}"

    rm $out/share/systemd/user/hyprpaper.service
    cp ${hyprpaper}/share/systemd/user/hyprpaper.service \
      $out/share/systemd/user/hyprpaper.service
    substituteInPlace $out/share/systemd/user/hyprpaper.service \
      --replace-fail "${hyprpaper}/bin/hyprpaper" "$out/bin/hyprpaper"
  '';
}
