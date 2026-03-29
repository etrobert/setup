{
  writeShellApplication,
  coreutils,
  curl,
  jq,
}:
writeShellApplication {
  name = "get-weather";
  runtimeInputs = [
    coreutils
    curl
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ../../waybar/.local/bin/get-weather.sh;
}
