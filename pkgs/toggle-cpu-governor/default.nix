{
  writeShellApplication,
  linuxPackages,
  kmod,
}:
writeShellApplication {
  name = "toggle-cpu-governor";
  runtimeInputs = [
    linuxPackages.cpupower
    kmod # for modprobe called by cpupower
  ];
  inheritPath = false;
  text = builtins.readFile ./toggle-cpu-governor;
}
