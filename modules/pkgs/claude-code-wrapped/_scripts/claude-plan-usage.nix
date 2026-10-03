{
  git,
  haskellPackages,
  lib,
  writers,
}:
writers.writeHaskellBin "claude-plan-usage" {
  libraries = [ haskellPackages.aeson ];
  # --set rather than --prefix: the script runs against exactly these tools.
  makeWrapperArgs = [
    "--set"
    "PATH"
    (lib.makeBinPath [ git ])
  ];
} (builtins.readFile ./claude-plan-usage.hs)
