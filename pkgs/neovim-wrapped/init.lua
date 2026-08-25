-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

-- Set the leader before any plugin config runs so their `<leader>` maps bind to
-- it. wrapNeovimUnstable emits plugin configs in reverse module-list order, so
-- a `mapleader` assignment inside a plugin can run after another plugin's maps.
vim.g.mapleader = " "

vim.loader.enable()

-- ui2 is private and experimental; wrapNeovimUnstable concatenates this file
-- and every plugin config into one init.lua, so an unguarded raise kills them all.
local ui2_ok, ui2_err = pcall(function()
	require("vim._core.ui2").enable({ msg = { targets = "msg" } })
end)

if not ui2_ok then
	vim.notify("vim._core.ui2 failed to enable: " .. ui2_err, vim.log.levels.ERROR)
end

vim.cmd.packadd("nvim.undotree")
