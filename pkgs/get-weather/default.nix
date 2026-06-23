{
  writeShellApplication,
  curl,
  jq,
}:
writeShellApplication {
  name = "get-weather";
  runtimeInputs = [
    curl
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./get-weather.sh;
}
