return {
	"stevearc/oil.nvim",
	opts = {},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
	keys = {
		{ "<leader>pv", "<CMD>Oil<CR>", desc = "Open Parent Directory" },
		{ "-", "<CMD>Oil<CR>", desc = "Open Parent Directory" },
		{
			"<leader>wd",
			function()
				vim.cmd("Oil " .. vim.fn.getcwd())
			end,
			desc = "Open Current Working Directory",
		},
	},
}
