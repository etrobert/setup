_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      # macOS uses the signed upstream app instead: wrapping it breaks its signature,
      # and TCC then re-prompts for permissions on every rebuild.
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        ghostty-wrapped = self'.legacyPackages.wrapPackage {
          package = pkgs.ghostty;
          # Ghostty is a terminal emulator that launches shells and user programs, so
          # it must inherit the caller's PATH rather than having it cleared or replaced.
          inheritPath = true;
          flags = [ "--config-file=${./config}" ];

          # Both files launch Ghostty on D-Bus activation and point at the unwrapped
          # binary; patch them so an activated instance is the wrapper.
          filesToPatch = [
            "$out/share/dbus-1/services/com.mitchellh.ghostty.service"
            "$out/share/systemd/user/app-com.mitchellh.ghostty.service"
          ];
        };
      };
    };
}
