{ pkgs, ... }:
let
  tidal-fmt = pkgs.callPackage ./tidal-fmt.nix { };
in
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.conform-nvim;
      config = builtins.readFile ./config.lua;
      extraPackages = with pkgs; [
        stylua
        prettierd
        isort # python import sorter
        black # python formatter
        shfmt
        rustfmt
        nixfmt
        tidal-fmt # ormolu-based formatter for .tidal files
      ];
    }
  ];
}
