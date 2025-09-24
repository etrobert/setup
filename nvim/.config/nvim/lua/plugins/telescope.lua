vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-telescope/telescope-ui-select.nvim",
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
})

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

require("telescope").load_extension("ui-select")

-- Try to load fzf extension, build if it fails
local fzf_ok = pcall(require("telescope").load_extension, "fzf")
if not fzf_ok then
	vim.notify("fzf extension failed to load, attempting to build...", vim.log.levels.INFO)
	local fzf_path = vim.fn.stdpath("data") .. "/site/pack/core/opt/telescope-fzf-native.nvim"
	if vim.fn.isdirectory(fzf_path) ~= 1 then
		vim.notify("telescope-fzf-native plugin not found", vim.log.levels.WARN)
		return
	end

	local result = vim.system({ "make" }, { cwd = fzf_path, text = true }):wait()
	if result.code ~= 0 then
		vim.notify(
			string.format("Failed to build telescope-fzf-native (exit code %d)", result.code),
			vim.log.levels.ERROR
		)
		return
	end

	vim.notify("Built telescope-fzf-native. Please restart Neovim to use fzf sorter.", vim.log.levels.INFO)
end

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", require("telescope.multigrep"), { desc = "Live Grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_workspace_symbols, { desc = "LSP Workspace Symbols" })
vim.keymap.set("n", "<leader>ft", builtin.builtin, { desc = "Telescope Pickers" })
vim.keymap.set("n", "<leader>fp", function()
	builtin.find_files({
		cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
	})
end, { desc = "Find File in Lazy Plugins" })
vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Grep String" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })

vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git Commits" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git Status" })
vim.keymap.set("n", "<leader>gB", builtin.git_bcommits, { desc = "Git Buffer Commits" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git Branches" })
vim.keymap.set("n", "<leader>gS", builtin.git_stash, { desc = "Git Stash" })
vim.keymap.set("n", "<leader>gd", function()
	builtin.git_commits({
		git_command = { "git", "log", "--oneline", "main..HEAD" },
	})
end, { desc = "Git Branch Diff with Main" })
vim.keymap.set(
	"n",
	"<leader>gf",
	require("telescope.git-diverged-files").git_diverged_files,
	{ desc = "Files Changed Since Diverged from Main" }
)
