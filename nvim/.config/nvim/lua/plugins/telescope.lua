return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "folke/which-key.nvim" },
	-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/855
	opts = function()
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

		return {
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
		}
	end,
}
