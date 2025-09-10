vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/j-hui/fidget.nvim",
})

require("fidget").setup({})

vim.lsp.enable({
	"bashls",
	"eslint",
	"tailwindcss",
	"ts_ls",
	"rust_analyzer",
	"gopls",
	"lua_ls",
	"copilot",
})
