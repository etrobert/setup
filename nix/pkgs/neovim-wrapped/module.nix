{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.plugins = mkOption {
    type = types.listOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            plugin = mkOption { type = types.package; };
            luaConfig = mkOption {
              type = types.nullOr types.lines;
              default = null;
            };
            config = mkOption {
              type = types.nullOr types.lines;
              default = null;
            };
            extraPackages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
          };
          config.config = lib.mkIf (config.luaConfig != null) /* vim */ ''
            lua << EOF
            ${config.luaConfig}
            EOF
          '';
        }
      )
    );
    default = [ ];
  };
}
