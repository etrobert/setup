require("etrobert")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

vim.pack.add({
	"https://github.com/tpope/vim-surround",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/rcarriga/nvim-notify",
})

-- vim-fugitive
vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })

-- notify
vim.notify = require("notify")

require("plugins.catppuccin")
require("plugins.which-key")
require("plugins.harpoon")
require("plugins.lualine")
require("plugins.bufferline")
require("plugins.vim-tmux-navigator")
require("plugins.treesj")
require("plugins.trouble")
require("plugins.conform")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.colorizer")
require("plugins.lspconfig")
require("plugins.cmp")
require("plugins.nvim-ts-autotag")
