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
				g = {
					name = "Git",

					-- Lists git commits with diff preview
					-- checkout action <cr>
					-- reset mixed <C-r>m
					-- reset soft <C-r>s
					-- reset hard <C-r>h
					c = { builtin.git_commits, "Commits" },

					-- Lists buffer's git commits with diff preview and checks them out on <cr>
					B = { builtin.git_bcommits, "Buffer Commits" },

					-- builtin.git_bcommits_range
					-- Lists buffer's git commits in a range of lines.
					-- Use options from and to to specify the range.
					-- In visual mode, lists commits for the selected lines

					-- Lists current changes per file with diff preview and add action. (Multi-selection still WIP)
					s = { builtin.git_status, "Status" },

					-- Lists all branches with log preview
					-- checkout action <cr>
					-- track action <C-t>
					-- rebase action<C-r>
					-- create action <C-a>
					-- switch action <C-s>
					-- delete action <C-d>
					-- merge action <C-y>
					b = { builtin.git_branches, "Branches" },

					-- Lists stash items in current repository with ability to apply them on <cr>
					S = { builtin.git_stash, "Stash" },
				},
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
