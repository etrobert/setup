{
  writeShellApplication,
  makeDesktopItem,
  symlinkJoin,
  jq,
  self',
}:
let
  script = writeShellApplication {
    name = "open-url";
    runtimeInputs = [
      jq
      self'.packages.niri-wrapped
      self'.packages.zen-browser-wrapped
    ];
    inheritPath = false;
    text = builtins.readFile ./open-url;
  };

  desktopItem = makeDesktopItem {
    name = "open-url";
    exec = "open-url %u";
    desktopName = "Open URL";
    noDisplay = true;
    mimeTypes = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "text/html"
    ];
  };
in
symlinkJoin {
  name = "open-url";
  paths = [
    script
    desktopItem
  ];
}
