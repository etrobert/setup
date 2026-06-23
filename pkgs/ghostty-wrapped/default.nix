{
  ghostty,
  lib,
  stdenv,
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

  # The XDG desktop entry's Exec= points at the unwrapped binary, so launchers
  # (fuzzel, etc.) bypass the wrapper's --config-file flag. Repoint it at $out.
  # Linux-only: macOS has no desktop file and filesToPatch fails if it's absent.
  filesToPatch = lib.optional stdenv.hostPlatform.isLinux "$out/share/applications/com.mitchellh.ghostty.desktop";

  # Don't modify the .app: swapping its binary invalidates the code signature,
  # which macOS 27 SIGKILLs. The Dock bypasses this wrapper, so the host instead
  # delivers the GUI config via ~/.config/ghostty/config using this file.
  passthru.configFile = ./config;
}
