return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{ "<leader>ff", ":Telescope find_files<CR>", desc = "Find Files" },
		{ "<leader>fg", ":Telescope live_grep<CR>", desc = "Live Grep" },
		{ "<leader>fb", ":Telescope buffers<CR>", desc = "Buffers" },
		{ "<leader>fh", ":Telescope help_tags<CR>", desc = "Help Tags" },
		{ "<leader>fs", ":Telescope lsp_workspace_symbols<CR>", desc = "LSP Workspace Symbols" },
		{ "<leader>ft", ":Telescope builtin<CR>", desc = "Telescope Pickers" },

		{ "<leader>gc", ":Telescope git_commits<CR>", desc = "Git Commits" },
		{ "<leader>gs", ":Telescope git_status<CR>", desc = "Git Status" },
		{ "<leader>gB", ":Telescope git_bcommits<CR>", desc = "Git Buffer Commits" },
		-- { "<leader>gB", ":Telescope git_bcommits_range<CR>", desc = "Buffer Commits in Range" },
		{ "<leader>gb", ":Telescope git_branches<CR>", desc = "Git Branches" },
		{ "<leader>gS", ":Telescope git_stash<CR>", desc = "Git Stash" },
		{
			"<leader>gd",
			function()
				require("telescope.builtin").git_commits({
					git_command = { "git", "log", "--oneline", "main..HEAD" },
				})
			end,
			desc = "Git Branch Diff with Main",
		},

		{ "<C-p>", ":Telescope find_files<CR>", desc = "Find Files" },
	},
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
