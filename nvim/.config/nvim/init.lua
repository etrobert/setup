require("etrobert")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

vim.pack.add({
	"https://github.com/catppuccin/nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/tpope/vim-surround",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/rcarriga/nvim-notify",
	"https://github.com/NvChad/nvim-colorizer.lua",
	"https://github.com/Wansmer/treesj",
	"https://github.com/akinsho/bufferline.nvim",
})

-- catppuccin
vim.cmd("colorscheme catppuccin-macchiato")

-- vim-fugitive
vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })

-- notify
vim.notify = require("notify")

-- colorizer
require("colorizer").setup({ user_default_options = { tailwind = true } })

-- treesj
require("treesj").setup({ max_join_length = 500 })

-- bufferline
require("bufferline").setup({ options = { diagnostics = "nvim_lsp" } })

require("plugins.which-key")
require("plugins.harpoon")
require("plugins.lualine")
require("plugins.vim-tmux-navigator")
require("plugins.trouble")
require("plugins.conform")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.lspconfig")
require("plugins.cmp")
require("plugins.nvim-ts-autotag")
