return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "folke/which-key.nvim" },
	-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/855
	opts = function()
		local builtin = require("telescope.builtin")
		local wk = require("which-key")

		wk.add({
			{ "<leader>f", group = "Find" },
			{ "<leader>ff", builtin.find_files, desc = "Find Files" },
			{ "<leader>fg", builtin.live_grep, desc = "Live Grep" },
			{ "<leader>fb", builtin.buffers, desc = "Buffers" },
			{ "<leader>fh", builtin.help_tags, desc = "Help Tags" },
			{ "<leader>fs", builtin.lsp_workspace_symbols, desc = "LSP Workspace Symbols" },
			{ "<leader>ft", builtin.builtin, desc = "Telescope Pickers" },

			{ "<leader>g", group = "Git" },
			-- Lists git commits with diff preview
			-- checkout action <cr>
			-- reset mixed <C-r>m
			-- reset soft <C-r>s
			-- reset hard <C-r>h
			{ "<leader>gc", builtin.git_commits, desc = "Commits" },

			-- Lists buffer's git commits with diff preview and checks them out on <cr>
			{ "<leader>gB", builtin.git_bcommits, desc = "Buffer Commits" },

			-- builtin.git_bcommits_range
			-- Lists buffer's git commits in a range of lines.
			-- Use options from and to to specify the range.
			-- In visual mode, lists commits for the selected lines

			-- Lists current changes per file with diff preview and add action. (Multi-selection still WIP)
			{ "<leader>gs", builtin.git_status, desc = "Status" },

			-- Lists all branches with log preview
			-- checkout action <cr>
			-- track action <C-t>
			-- rebase action<C-r>
			-- create action <C-a>
			-- switch action <C-s>
			-- delete action <C-d>
			-- merge action <C-y>
			{ "<leader>gb", builtin.git_branches, desc = "Branches" },

			-- Lists stash items in current repository with ability to apply them on <cr>
			{ "<leader>gS", builtin.git_stash, desc = "Stash" },

			{ "<C-p>", builtin.find_files, desc = "Find Files" },
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
