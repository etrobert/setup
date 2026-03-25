{
  writeShellApplication,
  gawk,
  gnugrep,
  libnotify,
  wireplumber,
}:
writeShellApplication {
  name = "volume-control";
  runtimeInputs = [
    gawk
    gnugrep
    libnotify
    wireplumber
  ];
  inheritPath = false;
  text = builtins.readFile ./volume-control;
}
