local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local pickers = require("telescope.pickers")

local M = {}

M.git_diverged_files = function()
	local opts = {
		prompt_title = "Files Changed Since Diverged from Main",
		cwd = vim.fn.getcwd(),
	}

	local base = vim.fn.trim(vim.fn.system("git merge-base main HEAD"))

	local finder = finders.new_oneshot_job({ "git", "diff", "--name-only", base .. "..HEAD" }, opts)

	local previewer = previewers.new_termopen_previewer({
		get_command = function(entry)
			return { "git", "diff", base .. "..HEAD", "--", entry.value }
		end,
	})

	pickers.new(opts, { finder = finder, previewer = previewer }):find()
end

return M
