{
  self',
  lib,
  symlinkJoin,
  makeWrapper,
  niri,
}:
symlinkJoin {
  name = "niri-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ niri ];
  postBuild = ''
    wrapProgram $out/bin/niri \
      --set NIRI_CONFIG ${./config.kdl}
      --prefix PATH : ${lib.makeBinPath [ self'.packages.waybar-wrapped ]}

    rm $out/share/systemd/user/niri.service
    cp ${niri}/share/systemd/user/niri.service \
      $out/share/systemd/user/niri.service
    substituteInPlace $out/share/systemd/user/niri.service \
      --replace-fail "${niri}/bin/niri" "$out/bin/niri"
  '';
  passthru.providedSessions = niri.passthru.providedSessions;
}
