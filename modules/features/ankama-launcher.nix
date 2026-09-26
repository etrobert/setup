{ self, ... }:
{
  flake.nixosModules.ankama-launcher =
    { pkgs, ... }:
    {
      # Dofus 3 aborts on startup without it.
      imports = [ self.nixosModules.xwayland-client-list ];

      allowedUnfreePackages = [ "ankama-launcher" ];

      environment.systemPackages = [ pkgs.ankama-launcher ];
    };
}
