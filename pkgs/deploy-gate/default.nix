{
  coreutils,
  gitMinimal,
  writeShellApplication,
}:

writeShellApplication {
  name = "deploy-gate";

  runtimeInputs = [
    coreutils
    gitMinimal
  ];

  inheritPath = false;

  text = builtins.readFile ./deploy-gate.sh;
}
