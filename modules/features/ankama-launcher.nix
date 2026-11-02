{ self, ... }:
{
  flake.nixosModules.ankama-launcher =
    { lib, pkgs, ... }:
    {
      # Dofus 3 aborts on startup without it.
      imports = [ self.nixosModules.xwayland-client-list ];

      allowedUnfreePackages = [ "ankama-launcher" ];

      environment.systemPackages = [
        # 3.15.5 crashes trying to self-update to 3.15.10: NixOS/nixpkgs#579240
        (
          assert lib.assertMsg (lib.versionOlder pkgs.ankama-launcher.version "3.15.10")
            "nixpkgs ankama-launcher ${pkgs.ankama-launcher.version} includes NixOS/nixpkgs#579240: use it again";
          pkgs.callPackage (builtins.fetchurl {
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/1850e4b7e90304b9f09c3dcfddb5b2b24a99d40c/pkgs/by-name/an/ankama-launcher/package.nix";
            sha256 = "sha256-fvWIAuBz7WSLMFRwJ8U7oS+V2nb1ubRAHivQoTG/Blc=";
          }) { }
        )
      ];
    };
}
