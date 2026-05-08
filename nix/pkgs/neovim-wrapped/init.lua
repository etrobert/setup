-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("vim._core.ui2").enable({ msg = { targets = "msg" } })

vim.cmd.packadd("nvim.undotree")
