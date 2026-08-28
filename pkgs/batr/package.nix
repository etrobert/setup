{
  writeShellApplication,
  findutils,
  bat,
}:
writeShellApplication {
  name = "batr";
  runtimeInputs = [
    findutils
    bat
  ];
  inheritPath = false;
  text = ''find "$1" -type f -exec bat {} +'';
}
