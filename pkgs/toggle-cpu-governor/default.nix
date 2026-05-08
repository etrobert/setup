{
  writeShellApplication,
  coreutils,
  linuxPackages,
  kmod,
}:
writeShellApplication {
  name = "toggle-cpu-governor";
  runtimeInputs = [
    coreutils
    linuxPackages.cpupower
    kmod # for modprobe called by cpupower
  ];
  inheritPath = false;
  text = builtins.readFile ./toggle-cpu-governor;
}
