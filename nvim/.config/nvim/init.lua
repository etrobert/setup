require("etrobert")

require("config.lazy")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

require("native-plugins.catppuccin")
require("native-plugins.notify")
require("native-plugins.colorizer")
