{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.conform-nvim;
      luaConfig = builtins.readFile ./config.lua;
      extraPackages = with pkgs; [
        stylua
        prettierd
        isort # python import sorter
        black # python formatter
        shfmt
        rustfmt
        nixfmt
      ];
    }
  ];
}
