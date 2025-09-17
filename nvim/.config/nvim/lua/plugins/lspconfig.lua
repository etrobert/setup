vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

vim.lsp.config["knip_lsp"] = {
	cmd = { "node", "/Users/etiennerobert/work/knip-lsp/out/main.js", "--stdio" },
	filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json" },
	root_markers = { ".git", "package.json" },
}

vim.lsp.enable({
	"bashls",
	"eslint",
	"tailwindcss",
	"ts_ls",
	"rust_analyzer",
	"gopls",
	"lua_ls",
	"copilot",
	"knip_lsp",
})
