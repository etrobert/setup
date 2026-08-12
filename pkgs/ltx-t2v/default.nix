{ writeShellApplication, python3 }:
writeShellApplication {
  name = "ltx-t2v";
  runtimeInputs = [ python3 ];
  inheritPath = false;
  text = ''
    exec python3 ${./ltx-t2v.py} "$@"
  '';
}
