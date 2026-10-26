{ self, ... }:
{
  flake.nixosModules.ankama-launcher =
    { lib, pkgs, ... }:
    {
      # Dofus 3 aborts on startup without it.
      imports = [ self.nixosModules.xwayland-client-list ];

      allowedUnfreePackages = [ "ankama-launcher" ];

      environment.systemPackages = [
        # 3.15.5 crashes trying to self-update to 3.15.9: NixOS/nixpkgs#579240
        (
          assert lib.assertMsg (lib.versionOlder pkgs.ankama-launcher.version "3.15.9")
            "nixpkgs ankama-launcher ${pkgs.ankama-launcher.version} includes NixOS/nixpkgs#579240: use it again";
          pkgs.callPackage (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/f9321ae1f554229584d218eab51005c11e93176f/pkgs/by-name/an/ankama-launcher/package.nix";
            sha256 = "sha256-GbuXbpbyCVZsahbH+J8XwNd9pCukJVILV0b63xJNtnk=";
          }) { }
        )
      ];
    };
}
