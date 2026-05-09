{
  symlinkJoin,
  makeBinaryWrapper,
  ghostty,
}:
symlinkJoin {
  name = "ghostty-wrapped";
  # makeBinaryWrapper produces a compiled Mach-O binary rather than a shell
  # script. macOS refuses to launch shell scripts as .app bundle executables
  # ("does not have permission to open (null)"), so this is required on Darwin.
  nativeBuildInputs = [ makeBinaryWrapper ];
  paths = [ ghostty ];
  meta.mainProgram = "ghostty";
  postBuild = ''
    wrapProgram $out/bin/ghostty \
      --add-flags "--config-file=${./config}"

    # On macOS, the .app bundle's binary symlinks directly to the unwrapped
    # binary, bypassing the wrapper when launched from the Dock. Replace it.
    if [ -d "$out/Applications/Ghostty.app" ]; then
      rm $out/Applications/Ghostty.app/Contents/MacOS/ghostty
      ln -s $out/bin/ghostty $out/Applications/Ghostty.app/Contents/MacOS/ghostty
    fi
  '';
}
