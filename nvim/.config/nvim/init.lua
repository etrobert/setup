-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

-- TODO: Remove, this deletes all installed plugins
local all = vim.iter(vim.pack.get())
	:map(function(x)
		return x.spec.name
	end)
	:totable()
vim.pack.del(all)

require("etrobert")

vim.cmd.packadd("nvim.undotree")

-- require("hardtime").setup()

-- TODO: Fix this is injected before plugins are loaded
-- require("etrobert.startup_banner").setup()
