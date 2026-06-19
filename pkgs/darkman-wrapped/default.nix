{
  darkman,
  writeTextDir,
  wrapPackage,
}:
let
  config = writeTextDir "darkman/config.yaml" /* yaml */ ''
    lat: 52.5
    lng: 13.4
    usegeoclue: true
  '';
in
wrapPackage {
  package = darkman;
  env.XDG_CONFIG_HOME = config;
  # Validate config at build time (runs after wrapProgram sets XDG_CONFIG_HOME).
  postBuild = ''
    $out/bin/darkman check
  '';
}
