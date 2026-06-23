{
  ghostty,
  rsync,
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
  # rsync replicates nix-darwin's app deployment in the build (see postWrap).
  nativeBuildInputs = [ rsync ];
  postWrap = [
    # On macOS, the .app bundle's binary symlinks directly to the unwrapped
    # binary, bypassing the wrapper when launched from the Dock. Replace it with
    # the wrapper binary so the Dock uses the wrapper too — but that swap
    # invalidates the bundle's code signature: Contents/_CodeSignature/
    # CodeResources still seals the original binary. Older macOS tolerated the
    # mismatch, but macOS 27 SIGKILLs such a GUI launch ("Code Signature
    # Invalid" / "Launch Constraint Violation") — the app crashes instantly from
    # the Dock while still running fine from the CLI (only GUI launches check
    # the bundle seal). Re-sign ad-hoc to match the swapped-in wrapper.
    #
    # Stripping the signature instead of re-signing is not an option here:
    # `codesign --remove-signature` also drops the main executable's own ad-hoc
    # signature, which Apple Silicon requires to exec at all (the binary is then
    # SIGKILLed), and merely deleting _CodeSignature leaves a present-yet-invalid
    # signature that macOS 27 still kills.
    #
    # The signature must match the *deployed* bundle, not the symlinkJoin one.
    # symlinkJoin leaves the .app's files as symlinks into the read-only store,
    # and nix-darwin's activation deploys the bundle with `rsync
    # --copy-unsafe-links`, turning every store-pointing symlink into a real
    # file (framework-internal relative symlinks are preserved). codesign also
    # refuses to sign while Info.plist is a symlink ("must be a regular file"),
    # so materialize the bundle the same way activation will, then sign that.
    # A single `codesign --force --sign -` on the bundle re-seals CodeResources
    # and re-signs the swapped-in main executable in one step.
    #
    # codesign re-seals the whole bundle (rewriting CodeResources), which
    # nixpkgs' sigtool cannot do — it only signs Mach-O files and throws
    # NotAMachOFileException on a .app — so use the system /usr/bin/codesign.
    # The Darwin host builds with sandbox = false, so the absolute path resolves.
    #
    # The guard makes this a no-op on Linux, where there is no .app bundle.
    ''
      if [ -d "$out/Applications/Ghostty.app" ]; then
        app=$out/Applications/Ghostty.app

        # Materialize the bundle exactly as nix-darwin activation deploys it.
        rsync --archive --copy-unsafe-links --chmod=u+w "$app/" "$NIX_BUILD_TOP/Ghostty.app/"
        rm -rf "$app"
        mv "$NIX_BUILD_TOP/Ghostty.app" "$app"

        rm $app/Contents/MacOS/ghostty
        cp $out/bin/ghostty $app/Contents/MacOS/ghostty

        /usr/bin/codesign --force --sign - $app
      fi
    ''
  ];
}
