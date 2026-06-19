{
  writeTextDir,
  darkman,
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
  env.XDG_CONFIG_HOME = "${config}";
  # Fail the build on an invalid config rather than at service start-up.
  checks = [ "XDG_CONFIG_HOME=${config} $out/bin/darkman check" ];
}
