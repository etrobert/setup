# Markdown table of flake inputs whose rev changed between two lockfiles.
{ writeShellApplication, jq }:
writeShellApplication {
  name = "flake-input-table";
  runtimeInputs = [ jq ];
  inheritPath = false;
  text = builtins.readFile ./flake-input-table.sh;
}
