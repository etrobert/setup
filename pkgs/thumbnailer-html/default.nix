{
  writeShellApplication,
  writeTextDir,
  symlinkJoin,
  lib,
  coreutils,
  chromium,
  imagemagick,
}:
let
  script = writeShellApplication {
    name = "html-thumbnailer";

    runtimeInputs = [
      coreutils
      chromium
      imagemagick
    ];

    inheritPath = false;
    text = builtins.readFile ./html-thumbnailer;
  };

  entry = writeTextDir "share/thumbnailers/html.thumbnailer" /* ini */ ''
    [Thumbnailer Entry]
    TryExec=${lib.getExe script}
    Exec=${lib.getExe script} --input %i --output %o --size %s
    MimeType=text/html;application/xhtml+xml;
  '';
in
symlinkJoin {
  name = "thumbnailer-html";

  paths = [
    script
    entry
  ];
}
