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
		{
			"<leader>fp",
			function()
				require("telescope.builtin").find_files({
					cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
				})
			end,
			desc = "Find File in Lazy Plugins",
		},

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
			function()
				local opts = {
					prompt_title = "Files Changed Since Diverged from Main",
					cwd = vim.fn.getcwd(),
				}

				local base = vim.fn.trim(vim.fn.system("git merge-base main HEAD"))

				local finder = require("telescope.finders").new_oneshot_job(
					{ "git", "diff", "--name-only", base .. "..HEAD" },
					opts
				)

				local previewer = require("telescope.previewers").new_termopen_previewer({
					get_command = function(entry)
						return { "git", "diff", base .. "..HEAD", "--", entry.value }
					end,
				})

				require("telescope.pickers")
					.new(opts, {
						finder = finder,
						previewer = previewer,
					})
					:find()
			end,
			desc = "Files Changed Since Diverged from Main",
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
