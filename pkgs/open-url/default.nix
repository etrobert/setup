{
  writeShellApplication,
  makeDesktopItem,
  symlinkJoin,
  glibc,
  jq,
  openssh,
  tmux,
  self',
}:
let
  script = writeShellApplication {
    name = "open-url";
    runtimeInputs = [
      # `getent` resolves the SSH client address to a name ssh will accept.
      glibc.getent
      jq
      openssh
      tmux
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
