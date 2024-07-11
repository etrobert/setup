local builtin = require("telescope.builtin")

local wk = require("which-key")

wk.register({
	["<leader>"] = {
		f = {
			name = "Find",
			f = { builtin.find_files, "Find Files" },
			g = { builtin.live_grep, "Live Grep" },
			b = { builtin.buffers, "Buffers" },
			h = { builtin.help_tags, "Help Tags" },
		},
		gs = { builtin.git_status, " Telescope Git Status" },
	},
	["<C-p>"] = { builtin.find_files, "Find Files" },
})
