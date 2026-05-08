local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local previewers_utils = require("telescope.previewers.utils")
local pickers = require("telescope.pickers")

local M = {}

M.git_diverged_files = function()
	local opts = {
		prompt_title = "Files Changed Since Diverged from Main",
		cwd = vim.fn.getcwd(),
	}

	local base = vim.fn.trim(vim.fn.system("git merge-base origin/main HEAD"))

	local finder = finders.new_oneshot_job({ "git", "diff", "--name-only", base .. "..HEAD" }, opts)

	local previewer = previewers.new_buffer_previewer({
		define_preview = function(self, entry)
			local cmd = { "git", "diff", base .. "..HEAD", "--", entry.value }
			previewers_utils.job_maker(cmd, self.state.bufnr, {
				value = entry.value,
				bufname = self.state.bufname,
				cwd = opts.cwd,
				callback = function(bufnr)
					vim.bo[bufnr].filetype = "diff"
				end,
			})
		end,
	})

	pickers.new(opts, { finder = finder, previewer = previewer }):find()
end

return M
