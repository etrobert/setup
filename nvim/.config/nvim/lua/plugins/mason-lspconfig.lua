return {
	"williamboman/mason-lspconfig.nvim",
	dependencies = {
		{ "williamboman/mason.nvim", opts = {} },
		{ "neovim/nvim-lspconfig" },
	},
	opts = function()
		local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

		local default_setup = function(server)
			require("lspconfig")[server].setup({ capabilities = lsp_capabilities })
		end

		return {
			ensure_installed = {
				"biome",
				"eslint",
				"tailwindcss",
				"ts_ls",
				"rust_analyzer",
				"bashls",
			},
			handlers = {
				default_setup,
				lua_ls = function()
					require("lspconfig").lua_ls.setup({
						capabilities = lsp_capabilities,
						settings = {
							Lua = {
								runtime = {
									version = "LuaJIT",
								},
								diagnostics = {
									globals = { "vim" },
								},
								workspace = {
									library = {
										vim.env.VIMRUNTIME,
									},
								},
							},
						},
					})
				end,
			},
		}
	end,
}
