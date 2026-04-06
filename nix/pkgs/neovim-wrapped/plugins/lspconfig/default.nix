{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;

      luaConfig = /* lua */ ''
        vim.lsp.enable({
        	"bashls",
        	"eslint",
        	"tailwindcss",
        	"ts_ls",
        	"rust_analyzer",
        	"gopls",
        	"lua_ls",
        	"nixd",
        	"cssls",
        	"html",
        	-- "copilot",
        })
      '';

      extraPackages = with pkgs; [
        bash-language-server
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
