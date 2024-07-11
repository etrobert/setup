return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/855
	opts = {
		defaults = {
			file_ignore_patterns = { "node_modules", "%.git%/", "package%-lock.json", "pnpm%-lock.yaml" },
		},
		pickers = {
			find_files = {
				hidden = true,
			},
			live_grep = {
				additional_args = { "--hidden" },
			},
		},
	},
}
