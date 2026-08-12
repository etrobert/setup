{
  writeShellApplication,
  writeTextDir,
  symlinkJoin,
  lib,
  coreutils,
  gnugrep,
  unzip,
  imagemagick,
}:
let
  script = writeShellApplication {
    name = "3mf-thumbnailer";

    runtimeInputs = [
      coreutils
      gnugrep
      unzip
      imagemagick
    ];

    inheritPath = false;
    text = builtins.readFile ./3mf-thumbnailer;
  };

  # Read by gnome-desktop's thumbnail factory, so Nautilus and Nemo pick it up
  # off XDG_DATA_DIRS. Tumbler ignores this spec, so Thunar cannot use it.
  entry = writeTextDir "share/thumbnailers/3mf.thumbnailer" /* ini */ ''
    [Thumbnailer Entry]
    TryExec=${lib.getExe script}
    Exec=${lib.getExe script} --input %i --output %o --size %s
    MimeType=model/3mf;
  '';
in
symlinkJoin {
  name = "thumbnailer-3mf";

  paths = [
    script
    entry
  ];
}
