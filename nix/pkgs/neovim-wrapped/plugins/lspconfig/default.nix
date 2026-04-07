{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;

      luaConfig = /* lua */ ''
        vim.lsp.config("gopls", {
        	settings = {
        		gopls = {
        			codelenses = {
        				gc_details = true,
        				generate = true,
        				test = true,
        				tidy = true,
        				upgrade_dependency = true,
        			},
        			hints = {
        				assignVariableTypes = true,
        				compositeLiteralFields = true,
        				compositeLiteralTypes = true,
        				constantValues = true,
        				functionTypeParameters = true,
        				parameterNames = true,
        				rangeVariableTypes = true,
        			},
        		},
        	},
        })

        vim.lsp.config("ts_ls", {
        	settings = {
        		typescript = {
        			inlayHints = {
        				includeInlayParameterNameHints = "all",
        				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        				includeInlayFunctionParameterTypeHints = true,
        				includeInlayVariableTypeHints = true,
        				includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        				includeInlayPropertyDeclarationTypeHints = true,
        				includeInlayFunctionLikeReturnTypeHints = true,
        				includeInlayEnumMemberValueHints = true,
        			},
        		},
        		javascript = {
        			inlayHints = {
        				includeInlayParameterNameHints = "all",
        				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        				includeInlayFunctionParameterTypeHints = true,
        				includeInlayVariableTypeHints = true,
        				includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        				includeInlayPropertyDeclarationTypeHints = true,
        				includeInlayFunctionLikeReturnTypeHints = true,
        				includeInlayEnumMemberValueHints = true,
        			},
        		},
        	},
        })

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
