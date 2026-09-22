{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        save-displays-rs = pkgs.rustPlatform.buildRustPackage {
          pname = "save-displays-rs";
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

          # Build against the IPC types of the niri that is actually installed,
          # rather than whatever crates.io version Cargo.toml names: the
          # compositor and its client then cannot disagree. cargo re-resolves
          # this offline because a path dependency needs no network.
          postPatch = ''
            cat >>Cargo.toml <<EOF

            [patch.crates-io]
            niri-ipc = { path = "${pkgs.niri.src}/niri-ipc" }
            EOF
          '';

          meta.platforms = lib.platforms.linux;
        };
      };
    };
}
