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
	"https://github.com/j-hui/fidget.nvim",
	"https://github.com/neovim/nvim-lspconfig",
})

require("catppuccin").setup({ float = { transparent = true, solid = false } })
vim.cmd("colorscheme catppuccin-macchiato")

-- vim-fugitive
vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })

require("notify").setup({ merge_duplicates = false, background_colour = "#25273A" })
vim.notify = require("notify")

require("colorizer").setup({ user_default_options = { tailwind = true } })

require("treesj").setup({ max_join_length = 500 })

require("bufferline").setup({ options = { diagnostics = "nvim_lsp" } })

require("fidget").setup({})

require("plugins.which-key")
require("plugins.harpoon")
require("plugins.lualine")
require("plugins.vim-tmux-navigator")
require("plugins.conform")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.cmp")
require("plugins.nvim-ts-autotag")
