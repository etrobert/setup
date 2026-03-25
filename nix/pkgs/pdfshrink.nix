{ pkgs }:
pkgs.writeShellApplication {
  name = "pdfshrink";
  runtimeInputs = with pkgs; [ ghostscript ];
  inheritPath = false;
  text = builtins.readFile ../../pdfshrink/.local/bin/pdfshrink.sh;
}
