-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

local catppuccin = {
	src = "https://github.com/catppuccin/nvim",
	name = "catppuccin",
	config = function()
		if os.getenv("WAYLAND_DISPLAY") or vim.fn.has("mac") == 1 then
			-- Graphical session (Wayland on Linux or macOS)
			require("catppuccin").setup({ float = { transparent = true, solid = false } })
			vim.cmd("colorscheme catppuccin-macchiato")
			-- else we're in a tty, using default theme
		end
	end,
}

local fugitive = {
	src = "https://github.com/tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })
	end,
}

local hardtime = {
	src = "https://github.com/m4xshen/hardtime.nvim",
	config = function()
		require("hardtime").setup()
	end,
}

local surround = {
	src = "https://github.com/tpope/vim-surround",
	-- vim-repeat to allow . repeat of vim-surround
	deps = { { src = "https://github.com/tpope/vim-repeat" } },
}

local fidget = {
	src = "https://github.com/j-hui/fidget.nvim",
	config = function()
		require("fidget").setup({})
	end,
}

local plugins = {
	catppuccin,
	fugitive,
	surround,
	require("plugins.bufferline"),
	-- hardtime,
	fidget,
	require("plugins.octo"),
}

local specs_unflat = vim.tbl_map(function(plugin)
	local deps = plugin.deps or {}
	table.insert(deps, { name = plugin.name, src = plugin.src })
	return deps
end, plugins)

local specs = vim.iter(specs_unflat):flatten():totable()

vim.pack.add(vim.list_extend({
	"https://github.com/nvim-tree/nvim-web-devicons",

	"https://github.com/rcarriga/nvim-notify",
	"https://github.com/Wansmer/treesj",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/chrisgrieser/nvim-spider",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/artemave/workspace-diagnostics.nvim",

	"https://github.com/alex-popov-tech/store.nvim",

	"https://github.com/github/copilot.vim",
}, specs))

vim.cmd.packadd("nvim.undotree")

require("notify").setup({ merge_duplicates = false, background_colour = "#25273A" })
vim.notify = require("notify")

require("treesj").setup({ max_join_length = 500 })

require("snacks").setup({ image = {} })

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
		{ "<leader>o", group = "Octo" },
	},
})

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
require("plugins.cmp")

for _, plugin in ipairs(plugins) do
	_ = plugin.config and plugin.config()
end

-- Disabled because this takes a monstrous amount of ressources
-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	group = vim.api.nvim_create_augroup("workspace-diagnostics", { clear = true }),
-- 	callback = function(args)
-- 		local client = vim.lsp.get_client_by_id(args.data.client_id)
-- 		if client then
-- 			require("workspace-diagnostics").populate_workspace_diagnostics(client, args.buf)
-- 		end
-- 	end,
-- })

require("etrobert.startup_banner").setup()
