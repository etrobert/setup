{
  coreutils,
  findutils,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "speak";
  runtimeInputs = [
    coreutils
    findutils
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./speak.sh;
}
