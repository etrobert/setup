# Inspired by https://github.com/hercules-ci/flake-parts/blob/main/modules/nixosModules.nix

{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    flake.sharedModules = mkOption {
      type = types.lazyAttrsOf types.deferredModule;
      default = { };
      description = ''
        Shared modules between Darwin and NixOS.

        You may use this for reusable pieces of configuration, service modules, etc.
      '';
    };
  };
}
