{
  git,
  lib,
  writers,
}:
writers.writeNuBin "claude-plan-usage" {
  # --set rather than --prefix: the script runs against exactly these tools.
  makeWrapperArgs = [
    "--set"
    "PATH"
    (lib.makeBinPath [ git ])
  ];
} ./claude-plan-usage.nu
