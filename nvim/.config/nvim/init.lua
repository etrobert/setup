-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.cmd.packadd("nvim.undotree")

require("plugins.treesitter")
require("plugins.cmp")

-- require("hardtime").setup()

require("etrobert.startup_banner").setup()
