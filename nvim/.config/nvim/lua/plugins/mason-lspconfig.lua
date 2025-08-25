return {
	"williamboman/mason-lspconfig.nvim",
	dependencies = {
		{ "williamboman/mason.nvim", opts = {} },
		"neovim/nvim-lspconfig",

		-- Useful status updates for LSP.
		{ "j-hui/fidget.nvim", opts = {} },
	},
	opts = {
		ensure_installed = {
			"biome",
			"eslint",
			"tailwindcss",
			"ts_ls",
			"rust_analyzer",
			"bashls",
			"gopls",
			"lua_ls",
		},
	},
}
