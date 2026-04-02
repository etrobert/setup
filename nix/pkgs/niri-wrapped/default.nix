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
      --add-flags "--config ${./config.kdl}"
  '';
  passthru.providedSessions = niri.passthru.providedSessions;
}
