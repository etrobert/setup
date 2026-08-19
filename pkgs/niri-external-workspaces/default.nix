{
  writeShellApplication,
  jq,
  niri,
  socat,
}:
writeShellApplication {
  name = "niri-external-workspaces";
  runtimeInputs = [
    jq
    niri
    socat
  ];
  inheritPath = false;
  text = builtins.readFile ./niri-external-workspaces;
}
