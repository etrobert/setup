{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.plugins = mkOption {
    type = types.listOf (
      types.submodule {
        options = {
          plugin = mkOption { type = types.package; };
          config = mkOption {
            type = types.nullOr types.lines;
            default = null;
          };
          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
          };
        };
      }
    );
    default = [ ];
  };
}
