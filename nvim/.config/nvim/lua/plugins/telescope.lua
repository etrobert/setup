return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		{ "nvim-telescope/telescope-ui-select.nvim" },
	},
	keys = {
		{ "<C-p>", ":Telescope find_files<CR>", desc = "Find Files" },
		{ "<leader>ff", ":Telescope find_files<CR>", desc = "Find Files" },
		{ "<leader>fg", require("telescope.multigrep"), desc = "Live Grep" },
		{ "<leader>fb", ":Telescope buffers<CR>", desc = "Buffers" },
		{ "<leader>fh", ":Telescope help_tags<CR>", desc = "Help Tags" },
		{ "<leader>fs", ":Telescope lsp_workspace_symbols<CR>", desc = "LSP Workspace Symbols" },
		{ "<leader>ft", ":Telescope builtin<CR>", desc = "Telescope Pickers" },
		{
			"<leader>fp",
			function()
				require("telescope.builtin").find_files({
					cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
				})
			end,
			desc = "Find File in Lazy Plugins",
		},
		{ "<leader>fw", ":Telescope grep_string<CR>", desc = "Grep String" },
		{ "<leader>fd", ":Telescope diagnostics<CR>", desc = "Diagnostics" },

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
		{
			"<leader>gf",
			require("telescope.git-diverged-files").git_diverged_files,
			desc = "Files Changed Since Diverged from Main",
		},
	},
	-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/855
	config = function()
		require("telescope").setup({
			defaults = {
				file_ignore_patterns = { "node_modules", "%.git%/", "package%-lock.json", "pnpm%-lock.yaml" },
			},
			pickers = {
				find_files = {
					hidden = true,
				},
				grep_string = {
					additional_args = { "--hidden" },
				},
				live_grep = {
					additional_args = { "--hidden" },
				},
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
			},
		})

		require("telescope").load_extension("fzf")
		require("telescope").load_extension("ui-select")
	end,
}
