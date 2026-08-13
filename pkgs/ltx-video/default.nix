{ writeShellApplication, python3 }:
writeShellApplication {
  name = "ltx-video";
  runtimeInputs = [ python3 ];
  inheritPath = false;
  text = ''
    exec python3 ${./ltx-video.py} "$@"
  '';
}
