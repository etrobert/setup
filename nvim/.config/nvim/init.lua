-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.cmd.packadd("nvim.undotree")

-- TODO: Fix this is injected before plugins are loaded
-- require("etrobert.startup_banner").setup()
