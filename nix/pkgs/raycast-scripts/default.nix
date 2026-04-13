{ writeScriptBin, symlinkJoin }:
symlinkJoin {
  name = "raycast-scripts";
  paths = [
    (writeScriptBin "meet" (builtins.readFile ./meet.sh))
    (writeScriptBin "git-standup" (builtins.readFile ./git-standup.sh))
  ];
}
