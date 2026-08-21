{
  writeShellApplication,
  makeDesktopItem,
  symlinkJoin,
  chromium,
}:
# Linear ships desktop apps for macOS and Windows only, so run the web app in
# a Chromium app window.
let
  script = writeShellApplication {
    name = "linear";
    runtimeInputs = [ chromium ];
    inheritPath = false;
    text = ''
      exec chromium --app=https://linear.app/ "$@"
    '';
  };

  desktopItem = makeDesktopItem {
    name = "linear";
    exec = "linear";
    desktopName = "Linear";
    icon = "${./icon.svg}";
    categories = [ "Development" ];
    # Chromium derives an app window's app_id from the --app URL's host.
    startupWMClass = "chrome-linear.app__-Default";
  };
in
symlinkJoin {
  name = "linear";
  paths = [
    script
    desktopItem
  ];
}
