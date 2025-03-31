-- Source: https://github.com/nvim-telescope/telescope.nvim/issues/3130

local previewers = require("telescope.previewers")
local utils = require("telescope.utils")
local from_entry = require("telescope.from_entry")

local git_command = utils.__git_command

local M = {}

M.git_difftastic_previewer = function(opts)
	return previewers.new_termopen_previewer({
		title = "Git File Difftastic Preview",

		get_command = function(entry)
			local command = git_command({ "--no-pager", "diff" }, opts)

			if entry.status and (entry.status == "??" or entry.status == "A ") then
				local p = from_entry.path(entry, true, false)
				if p == nil or p == "" then
					return
				end
				table.insert(command, { "--no-index", "/dev/null" })
			else
				table.insert(command, { "HEAD", "--" })
			end

			return utils.flatten({ utils.flatten(command), entry.value })
		end,

		scroll_fn = function(self, direction)
			if not self.state then
				return
			end

			local bufnr = self.state.termopen_bufnr
			-- 0x05 -> <C-e>; 0x19 -> <C-y>
			local input = direction > 0 and string.char(0x05) or string.char(0x19)
			local count = math.abs(direction)

			vim.api.nvim_win_call(vim.fn.bufwinid(bufnr), function()
				vim.cmd([[normal! ]] .. count .. input)
			end)
		end,
	})
end

return M
