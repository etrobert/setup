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
	config = function(_, opts)
		-- TODO: Remove all copilot stuff once its available
		-- with ensure_installed = { "copilot" }
		require("mason-lspconfig").setup(opts)

		-- Ensure copilot-language-server is installed via Mason
		local mason_registry = require("mason-registry")
		if not mason_registry.is_installed("copilot-language-server") then
			mason_registry.get_package("copilot-language-server"):install()
		end

		vim.lsp.enable("copilot")
	end,
}
