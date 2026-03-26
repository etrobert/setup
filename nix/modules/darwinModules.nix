# Inspired by https://github.com/hercules-ci/flake-parts/blob/main/modules/nixosModules.nix

{ lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
in
{
  options = {
    flake.darwinModules = mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      default = { };
      apply = mapAttrs (
        k: v: {
          _class = "darwin";
          _file = "${toString moduleLocation}#darwinModules.${k}";
          imports = [ v ];
        }
      );
      description = ''
        Shared modules between Darwin and NixOS.

        You may use this for reusable pieces of configuration, service modules, etc.
      '';
    };
  };
}
