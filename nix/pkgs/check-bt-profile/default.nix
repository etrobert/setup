{
  writeShellApplication,
  pulseaudio,
  gnugrep,
  gawk,
}:
writeShellApplication {
  name = "check-bt-profile";
  runtimeInputs = [
    pulseaudio
    gnugrep
    gawk
  ];
  inheritPath = false;
  text = builtins.readFile ./check-bt-profile;
}
