vim.pack.add({
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/akinsho/bufferline.nvim",
})

require("bufferline").setup({ options = { diagnostics = "nvim_lsp" } })

