{
  prettier,
  writeShellApplication,
}:
writeShellApplication {
  name = "format-file";
  runtimeInputs = [ prettier ];
  inheritPath = false;
  text = builtins.readFile ./format-file.sh;
}
