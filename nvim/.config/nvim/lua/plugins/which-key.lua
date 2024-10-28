return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {
		spec = {
			{ "<leader>b", group = "Buffer" },
			{ "<leader>g", group = "Telescope Git" },
			{ "<leader>f", group = "Telescope Files" },
			{ "<leader>x", group = "Trouble" },
		},
	},
}
