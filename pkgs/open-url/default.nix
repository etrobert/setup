{
  lib,
  writeShellApplication,
  makeDesktopItem,
  symlinkJoin,
  jq,
  niri-wrapped,
  zen-browser-wrapped,
}:
let
  script = writeShellApplication {
    name = "open-url";
    runtimeInputs = [
      jq
      niri-wrapped
      zen-browser-wrapped
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
  meta.platforms = lib.platforms.linux;
  name = "open-url";
  paths = [
    script
    desktopItem
  ];
}
