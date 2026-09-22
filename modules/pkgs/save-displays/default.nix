{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        save-displays = pkgs.rustPlatform.buildRustPackage {
          pname = "save-displays";
          version = "0.1.0";
          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./Cargo.toml
              ./Cargo.lock
              ./src
            ];
          };
          cargoLock.lockFile = ./Cargo.lock;

          # niri-ipc comes from the niri that is actually installed, so the
          # compositor and its client cannot disagree about the protocol.
          # Cargo.toml points at ./niri, which is this symlink here and in a
          # checkout; the whole tree, because niri-ipc inherits from its
          # workspace root.
          postPatch = "ln --symbolic ${pkgs.niri.src} niri";

          meta.platforms = lib.platforms.linux;
        };
      };
    };
}
