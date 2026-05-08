_:
let
  unfree =
    { config, lib, ... }:
    {
      options.allowedUnfreePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of unfree package names to allow";
      };

      config.nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) config.allowedUnfreePackages;
    };
in
{
  flake.nixosModules.unfree = unfree;
  flake.darwinModules.unfree = unfree;
}
