{ self, ... }:
{
  flake.nixosModules.ankamaLauncher =
    { pkgs, ... }:
    {
      # Dofus 3 aborts on startup without it.
      imports = [ self.nixosModules.xwaylandClientList ];

      allowedUnfreePackages = [ "ankama-launcher" ];

      environment.systemPackages = [ pkgs.ankama-launcher ];
    };
}
