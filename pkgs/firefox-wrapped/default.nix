{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      build =
        av1:
        (lib.evalModules {
          modules = [
            ./module.nix
            { inherit av1; }
          ];
          specialArgs = { inherit pkgs self; };
        }).config.wrapper;
    in
    {
      packages = {
        firefox-wrapped = build true;
        firefox-wrapped-no-av1 = build false;
      };
    };

  flake.nixosModules.firefox =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.wrappers.firefox = lib.mkOption {
        type = lib.types.submoduleWith {
          modules = [ ./module.nix ];
          specialArgs = { inherit pkgs self; };
        };
        default = { };
      };

      config.wrappers.firefox.av1 = lib.mkDefault config.gpu.hasAv1Decode;
    };
}
