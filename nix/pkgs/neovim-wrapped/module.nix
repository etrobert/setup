{ lib, ... }:
{
  options.plugins = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          plugin = lib.mkOption { type = lib.types.package; };
          config = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
        };
      }
    );
    default = [ ];
  };
}
