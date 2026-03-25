{ writeShellApplication, coreutils }:
writeShellApplication {
  name = "check-bt-profile";
  runtimeInputs = [
    coreutils
  ];
  inheritPath = false;
  text = builtins.readFile ./check-bt-profile;
}
