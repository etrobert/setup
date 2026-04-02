{
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
  '';
  passthru.providedSessions = niri.passthru.providedSessions;
}
