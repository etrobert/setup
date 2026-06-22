{
  ghostty,
  wrapPackage,
}:
wrapPackage {
  package = ghostty;
  # makeBinaryWrapper produces a compiled binary rather than a shell script.
  # macOS refuses to launch shell scripts as .app bundle executables
  # ("does not have permission to open (null)"), so this is required on Darwin.
  binaryWrapper = true;
  # Ghostty is a terminal emulator that launches shells and user programs, so
  # it must inherit the caller's PATH rather than having it cleared or replaced.
  inheritPath = true;
  flags = [ "--config-file=${./config}" ];
  postWrap = [
    # On macOS, the .app bundle's binary symlinks directly to the unwrapped
    # binary, bypassing the wrapper when launched from the Dock. Replace it
    # with a symlink to $out/bin/ghostty so the Dock uses the wrapper too.
    # The guard makes this a no-op on Linux where no .app bundle is present.
    ''
      if [ -d "$out/Applications/Ghostty.app" ]; then
        rm $out/Applications/Ghostty.app/Contents/MacOS/ghostty
        ln -s $out/bin/ghostty $out/Applications/Ghostty.app/Contents/MacOS/ghostty
      fi
    ''
  ];
}
