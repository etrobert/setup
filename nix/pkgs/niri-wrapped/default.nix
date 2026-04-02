{
  self',
  lib,
  symlinkJoin,
  makeWrapper,
  niri,
  fuzzel,
  dev ? false,
}:
let
  config = if dev then "/home/soft/setup/nix/pkgs/niri-wrapped/config.kdl" else ./config.kdl;

  path = [
    self'.packages.waybar-wrapped
    self'.packages.volume-control
    fuzzel
  ];
in
symlinkJoin {
  name = "niri-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ niri ];
  meta.mainProgram = "niri";
  postBuild = ''
    ${niri}/bin/niri validate --config ${./config.kdl}

    wrapProgram $out/bin/niri \
      --set NIRI_CONFIG ${config} \
      --prefix PATH : ${lib.makeBinPath path}

    rm $out/share/systemd/user/niri.service
    cp ${niri}/share/systemd/user/niri.service \
      $out/share/systemd/user/niri.service
    substituteInPlace $out/share/systemd/user/niri.service \
      --replace-fail "${niri}/bin/niri" "$out/bin/niri"
  '';
  passthru.providedSessions = niri.passthru.providedSessions;
}
