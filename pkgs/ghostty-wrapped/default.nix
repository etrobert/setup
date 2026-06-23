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
    # the bundle seal). An unsigned bundle launches fine, but a present-yet-
    # invalid one is killed, so re-seal ad-hoc to match the swapped-in wrapper.
    #
    # The signature must match the *deployed* bundle, not the symlinkJoin one.
    # symlinkJoin leaves the .app's files as symlinks into the read-only store,
    # and nix-darwin's activation deploys the bundle with `rsync
    # --copy-unsafe-links`, turning every store-pointing symlink into a real
    # file (framework-internal relative symlinks are preserved). Signing the
    # symlinked shape would seal those resources as symlinks, so the seal breaks
    # the moment activation materializes them — an invalid signature again.
    # Materialize the bundle the same way here, then sign that.
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

        rm $app/Contents/_CodeSignature/CodeResources

        /usr/bin/codesign --force --sign - $app/Contents/MacOS/ghostty
        /usr/bin/codesign --force --sign - $app
      fi
    ''
  ];
}
