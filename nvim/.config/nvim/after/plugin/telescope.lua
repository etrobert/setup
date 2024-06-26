local builtin = require("telescope.builtin")

-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/855
require("telescope").setup({
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
})

local wk = require("which-key")

wk.register({
	["<leader>"] = {
		f = {
			name = "Find",
			f = { builtin.find_files, "Find Files" },
			g = { builtin.live_grep, "Live Grep" },
			b = { builtin.buffers, "Buffers" },
		},
		gs = { builtin.git_status, " Telescope Git Status" },
	},
	["<C-p>"] = { builtin.find_files, "Find Files" },
})
