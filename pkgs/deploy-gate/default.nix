{
  coreutils,
  gitMinimal,
  writeShellApplication,
}:

writeShellApplication {
  name = "deploy-gate";

  runtimeInputs = [
    gitMinimal
    coreutils
  ];

  inheritPath = false;

  text = builtins.readFile ./deploy-gate.sh;
}
