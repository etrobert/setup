{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;

      config = builtins.readFile ./config.lua;

      extraPackages = with pkgs; [
        bash-language-server
        go
        gopls
        lua-language-server
        marksman
        tailwindcss-language-server
        typescript-language-server
        vscode-langservers-extracted
        rust-analyzer
        nixd
        openscad-lsp
        texlab
      ];
    }
  ];
}
