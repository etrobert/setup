{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;

      luaConfig = builtins.readFile ./config.lua;

      extraPackages = with pkgs; [
        bash-language-server
        go
        gopls
        lua-language-server
        tailwindcss-language-server
        typescript-language-server
        vscode-langservers-extracted
        rust-analyzer
        nixd
      ];
    }
  ];
}
