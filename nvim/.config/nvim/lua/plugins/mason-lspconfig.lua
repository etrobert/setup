return {
	"williamboman/mason-lspconfig.nvim",
	dependencies = {
		{ "williamboman/mason.nvim", opts = {} },
		{ "neovim/nvim-lspconfig" },
	},
	opts = function()
		local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

		local default_setup = function(server)
			require("lspconfig")[server].setup({
				capabilities = lsp_capabilities,
			})
		end

		return {
			ensure_installed = {
				"biome",
				"eslint",
				"tailwindcss",
				"tsserver",
				"rust_analyzer",
			},
			handlers = {
				default_setup,
			},
		}
	end,
}
