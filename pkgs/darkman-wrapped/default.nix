{
  symlinkJoin,
  makeWrapper,
  writeTextDir,
  darkman,
}:
let
  config = writeTextDir "darkman/config.yaml" /* yaml */ ''
    lat: 52.5
    lng: 13.4
    usegeoclue: true
  '';
in

symlinkJoin {
  name = "darkman-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ darkman ];
  meta.mainProgram = "darkman";
  postBuild = ''
    XDG_CONFIG_HOME=${config} $out/bin/darkman check

    wrapProgram $out/bin/darkman \
      --set XDG_CONFIG_HOME ${config}
  '';
}
