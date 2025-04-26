-- Source: TJ DeVries
-- Source: https://www.youtube.com/watch?v=xdXE1tOT-qg
-- Source: https://github.com/tjdevries/config.nvim/blob/master/lua/custom/telescope/multi-ripgrep.lua

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config")
local make_entry = require("telescope.make_entry")
local sorters = require("telescope.sorters")

return function(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.fn.getcwd()

	local finder = finders.new_async_job({
		command_generator = function(prompt)
			if not prompt or prompt == "" then
				return nil
			end

			local pieces = vim.split(prompt, "  ")
			local args = { "rg" }

			if pieces[1] then
				table.insert(args, "-e")
				table.insert(args, pieces[1])
			end

			if pieces[2] then
				table.insert(args, "-g")
				table.insert(args, pieces[2])
			end

			local additional_args = {
				"--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
				"--hidden",
			}

			return vim.iter({ args, additional_args }):flatten():totable()
		end,
		entry_maker = make_entry.gen_from_vimgrep(opts),
		cwd = opts.cwd,
	})

	local fzy = opts.fzy_mod or require("telescope.algos.fzy")

	local sorter = sorters.Sorter:new({
		scoring_function = function()
			return 1
		end,
		highlighter = function(_, prompt, display)
			local pieces = vim.split(prompt, "  ")
			return fzy.positions(pieces[1], display)
		end,
	})

	pickers
		.new(opts, {
			debounce = 100,
			prompt_title = "Multi Grep",
			finder = finder,
			previewer = config.values.grep_previewer(opts),
			sorter = sorter,
		})
		:find()
end
