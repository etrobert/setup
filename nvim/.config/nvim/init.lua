require("etrobert")

require("config.lazy")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

vim.pack.add({ "https://github.com/rcarriga/nvim-notify" })
vim.notify = require("notify")
