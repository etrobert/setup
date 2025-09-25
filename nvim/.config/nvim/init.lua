-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

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
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/chrisgrieser/nvim-spider",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/m4xshen/hardtime.nvim",
	"https://github.com/folke/snacks.nvim",
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

require("snacks").setup({ image = {} })

---@diagnostic disable-next-line: missing-fields
require("nvim-ts-autotag").setup({
	opts = { enable_close = false, enable_rename = true, enable_close_on_slash = false },
})

local relative_path = { "filename", path = 1 }
require("lualine").setup({
	sections = { lualine_c = { relative_path }, lualine_x = { "filetype" } },
	inactive_sections = { lualine_c = { relative_path } },
})

require("which-key").setup({
	spec = {
		{ "<leader>b", group = "Buffer" },
		{ "<leader>g", group = "Telescope Git" },
		{ "<leader>f", group = "Telescope Files" },
	},
})

---@diagnostic disable-next-line: missing-fields
require("lazydev").setup({
	library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
})

-- nvim-spider
require("spider").setup({ skipInsignificantPunctuation = false })

vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>")
vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>")
vim.keymap.set({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>")

require("plugins.harpoon")
require("plugins.vim-tmux-navigator")
require("plugins.conform")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")

-- Lazy load cmp on InsertEnter
vim.api.nvim_create_autocmd("InsertEnter", {
	once = true,
	callback = function()
		require("plugins.cmp")
	end,
})

-- require("hardtime").setup()

require("etrobert.startup_banner").setup()
