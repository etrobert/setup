{ pkgs, ... }:
let
  tailwindcss-colorizer-cmp-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "tailwindcss-colorizer-cmp-nvim";
    version = "2024-01-01";
    src = pkgs.fetchFromGitHub {
      owner = "roobert";
      repo = "tailwindcss-colorizer-cmp.nvim";
      rev = "3d3cd95e4a4135c250faf83dd5ed61b8e5502b86";
      hash = "sha256-PIkfJzLt001TojAnE/rdRhgVEwSvCvUJm/vNPLSWjpY=";
    };
  };
in
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-cmp;
      luaConfig = builtins.readFile ./config.lua;
    }
    { plugin = pkgs.vimPlugins.cmp-nvim-lsp; }
    { plugin = pkgs.vimPlugins.cmp-buffer; }
    { plugin = pkgs.vimPlugins.cmp-path; }
    { plugin = pkgs.vimPlugins.cmp-cmdline; }
    { plugin = pkgs.vimPlugins.cmp_luasnip; }
    { plugin = pkgs.vimPlugins.luasnip; }
    { plugin = pkgs.vimPlugins.cmp-nvim-lsp-signature-help; }
    { plugin = tailwindcss-colorizer-cmp-nvim; }
    { plugin = pkgs.vimPlugins.friendly-snippets; }
    { plugin = pkgs.vimPlugins.cmp-emoji; }
  ];
}
