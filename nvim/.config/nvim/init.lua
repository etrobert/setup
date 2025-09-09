require("etrobert")

require("config.lazy")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

require("native-plugins.catppuccin")
require("native-plugins.surround")
require("native-plugins.fugitive")
require("native-plugins.which-key")
require("native-plugins.harpoon")
require("native-plugins.lualine")
require("native-plugins.notify")
require("native-plugins.colorizer")
