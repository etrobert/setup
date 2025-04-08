return {
	"stevearc/oil.nvim",
	opts = {
		-- Source: https://github.com/refractalize/oil-git-status.nvim
		win_options = { signcolumn = "yes:2" },
	},
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
