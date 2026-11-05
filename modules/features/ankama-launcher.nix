{ self, ... }:
{
  flake.nixosModules.ankama-launcher =
    { lib, pkgs, ... }:
    {
      # Dofus 3 aborts on startup without it.
      imports = [ self.nixosModules.xwayland-client-list ];

      allowedUnfreePackages = [ "ankama-launcher" ];

      environment.systemPackages = [
        # The launcher crashes trying to self-update once Ankama ships a newer release.
        (
          assert lib.assertMsg (lib.versionOlder pkgs.ankama-launcher.version "3.15.12")
            "nixpkgs ankama-launcher is ${pkgs.ankama-launcher.version}: drop the override";
          pkgs.ankama-launcher.overrideAttrs {
            version = "3.15.12";
            src = pkgs.fetchurl {
              url = "https://web.archive.org/web/20261105153642id_/https://launcher.cdn.ankama.com/installers/production/Ankama%20Launcher-Setup-x86_64.AppImage";
              hash = "sha256-8/3aYwp8RLUdVAQaj2gaOkC6wr52jUxT6Ht+pnezrsE=";
            };
          }
        )
      ];
    };
}
