{
  writeShellApplication,
  coreutils,
  ddcutil,
  gnugrep,
}:
writeShellApplication {
  name = "ddcci-register";
  runtimeInputs = [
    coreutils # seq & sleep
    ddcutil
    gnugrep
  ];
  inheritPath = false;
  text = builtins.readFile ./ddcci-register;
}
