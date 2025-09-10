vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/j-hui/fidget.nvim",
})

require("fidget").setup({})

vim.lsp.enable("bashls")
vim.lsp.enable("eslint")
vim.lsp.enable("tailwindcss")
vim.lsp.enable("ts_ls")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("copilot")
