{
  symlinkJoin,
  makeWrapper,
  mako,
}:
symlinkJoin {
  name = "mako-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ mako ];
  meta.mainProgram = "mako";
  postBuild = ''
    wrapProgram $out/bin/mako \
      --add-flags "--config ${./config}"
  '';
}
