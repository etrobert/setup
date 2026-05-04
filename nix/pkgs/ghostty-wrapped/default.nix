{
  symlinkJoin,
  makeWrapper,
  ghostty,
}:
symlinkJoin {
  name = "ghostty-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ ghostty ];
  meta.mainProgram = "ghostty";
  postBuild = ''
    wrapProgram $out/bin/ghostty \
      --add-flags "--config-file=${./config}"
  '';
}
