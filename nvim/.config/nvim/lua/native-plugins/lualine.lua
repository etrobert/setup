vim.pack.add({
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/nvim-lualine/lualine.nvim",
})

require("lualine").setup({
	sections = {
		lualine_c = {
			{
				"filename",
				path = 1, -- Show relative path
			},
		},
	},
	inactive_sections = {
		lualine_c = {
			{
				"filename",
				path = 1, -- Show relative path
			},
		},
	},
})