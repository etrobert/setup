{
  bc,
  coreutils,
  git,
  jq,
  writeShellApplication,
}:
let
  weekProgressScript = writeShellApplication {
    name = "week-progress";
    runtimeInputs = [ coreutils ];
    inheritPath = false;
    text = builtins.readFile ./week-progress.sh;
  };
in
writeShellApplication {
  name = "claude-plan-usage";
  runtimeInputs = [
    bc
    coreutils
    git
    jq
    weekProgressScript
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-plan-usage.sh;
}
