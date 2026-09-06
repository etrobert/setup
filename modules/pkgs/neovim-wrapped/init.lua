-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

-- Set the leader before any plugin config runs so their `<leader>` maps bind to
-- it. wrapNeovimUnstable emits plugin configs in reverse module-list order, so
-- a `mapleader` assignment inside a plugin can run after another plugin's maps.
vim.g.mapleader = " "

vim.loader.enable()

require("vim._core.ui2").enable({ msg = { targets = "msg" } })

vim.cmd.packadd("nvim.undotree")
