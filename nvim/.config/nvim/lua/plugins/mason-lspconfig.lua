vim.pack.add({
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/j-hui/fidget.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
})

require("mason").setup({})
require("fidget").setup({})

require("mason-lspconfig").setup({
	ensure_installed = {},
})

vim.lsp.enable("bashls")
vim.lsp.enable("eslint")
vim.lsp.enable("tailwindcss")
vim.lsp.enable("ts_ls")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")
vim.lsp.enable("lua_ls")

-- TODO: Remove all copilot stuff once its available
-- with ensure_installed = { "copilot" }

-- Ensure copilot-language-server is installed via Mason
local mason_registry = require("mason-registry")
if not mason_registry.is_installed("copilot-language-server") then
	mason_registry.get_package("copilot-language-server"):install()
end

vim.lsp.enable("copilot")
