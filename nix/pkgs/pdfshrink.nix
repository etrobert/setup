{ writeShellApplication, ghostscript }:
writeShellApplication {
  name = "pdfshrink";
  runtimeInputs = [ ghostscript ];
  inheritPath = false;
  text = builtins.readFile ../../pdfshrink/.local/bin/pdfshrink.sh;
}
