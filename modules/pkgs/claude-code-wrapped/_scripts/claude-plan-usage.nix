{
  bc,
  coreutils,
  git,
  jq,
  writeShellApplication,
}:
let
  windowProgressScript = writeShellApplication {
    name = "window-progress";
    runtimeInputs = [ coreutils ];
    inheritPath = false;
    text = builtins.readFile ./window-progress.sh;
  };
in
writeShellApplication {
  name = "claude-plan-usage";
  runtimeInputs = [
    bc
    coreutils
    git
    jq
    windowProgressScript
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-plan-usage.sh;
}
