{
  symlinkJoin,
  makeWrapper,
  fuzzel,
}:
symlinkJoin {
  name = "fuzzel-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ fuzzel ];
  meta.mainProgram = "fuzzel";
  postBuild = ''
    # Niri runs as a systemd service with a minimal PATH. Fuzzel inherits that
    # PATH and uses it to exec apps from .desktop Exec= lines. Prefix the
    # system packages path so those apps are findable.
    wrapProgram $out/bin/fuzzel \
      --prefix PATH : /run/current-system/sw/bin
  '';
}
