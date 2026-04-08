-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("vim._core.ui2").enable({ msg = { targets = "msg" } })

require("etrobert")

vim.cmd.packadd("nvim.undotree")

-- TODO: Fix this is injected before plugins are loaded
-- require("etrobert.startup_banner").setup()
