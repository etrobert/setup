-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

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

-- nvim-spider
vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>")
vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>")
vim.keymap.set({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>")

require("plugins.harpoon")
require("plugins.vim-tmux-navigator")
require("plugins.conform")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.cmp")

-- Display startup time after everything loads
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Calculate time elapsed since we recorded start_time
		local elapsed = vim.fn.reltimefloat(vim.fn.reltime(vim.g.start_time)) * 1000
		local message = string.format("⚡ Neovim loaded in %.1fms", elapsed)
		vim.notify(message, vim.log.levels.INFO, { title = "Startup Time" })
	end,
})
