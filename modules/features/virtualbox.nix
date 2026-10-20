{
  flake.nixosModules.virtualbox =
    { lib, ... }:
    {
      virtualisation.virtualbox.host.enable = true;
      # Required for passing USB devices through to guests.
      users.users.soft.extraGroups = [ "vboxusers" ];

      # nixpkgs signs out-of-tree modules through kmodigest, which only runs
      # with the kernel's module make flags; virtualbox-modules omits them, so
      # no .ko.cer is produced and the modules aggregator fails. Port of
      # NixOS/nixpkgs#575381.
      nixpkgs.overlays = [
        (_: prev: {
          linuxPackages = prev.linuxPackages.extend (
            lpFinal: lpPrev: {
              virtualbox =
                assert lib.assertMsg (!lib.elem "VBOX_ALLOW_MODULE_SIGNING=1" lpPrev.virtualbox.makeFlags)
                  "nixpkgs virtualbox-modules now signs its modules (NixOS/nixpkgs#575381): drop the overlay in modules/features/virtualbox.nix";
                lpPrev.virtualbox.overrideAttrs (old: {
                  makeFlags = lpFinal.kernelModuleMakeFlags ++ old.makeFlags ++ [ "VBOX_ALLOW_MODULE_SIGNING=1" ];
                });
            }
          );
        })
      ];
    };
}
