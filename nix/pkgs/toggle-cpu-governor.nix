{ pkgs }:
pkgs.writeShellApplication {
  name = "toggle-cpu-governor";
  runtimeInputs = with pkgs; [
    coreutils
    linuxPackages.cpupower
    kmod # for modprobe called by cpupower
  ];
  inheritPath = false;
  text = builtins.readFile ../../cpupower/.local/bin/toggle-cpu-governor;
}
