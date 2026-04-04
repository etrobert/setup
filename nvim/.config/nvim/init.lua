-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")

local fugitive = {
	src = "https://github.com/tpope/vim-fugitive",
	setup = function()
		vim.keymap.set("n", "<leader>ds", ":Gdiffsplit<CR>", { desc = "Git diff split" })
	end,
}

local hardtime = {
	src = "https://github.com/m4xshen/hardtime.nvim",
	setup = function()
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
	setup = function()
		require("fidget").setup({})
	end,
}

-- TODO: Restore order
local plugins = {
	require("plugins.catppuccin"),
	fugitive,
	surround,
	require("plugins.bufferline"),
	require("plugins.nvim-ts-autotag"),
	require("plugins.snacks"),
	require("plugins.telescope"),
	require("plugins.nvim-notify"),
	require("plugins.lualine"),
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
	"https://github.com/Wansmer/treesj",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/chrisgrieser/nvim-spider",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/artemave/workspace-diagnostics.nvim",

	"https://github.com/alex-popov-tech/store.nvim",

	"https://github.com/github/copilot.vim",
}, specs))

vim.cmd.packadd("nvim.undotree")

require("treesj").setup({ max_join_length = 500 })

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
require("plugins.treesitter")
require("plugins.cmp")

for _, plugin in ipairs(plugins) do
	_ = plugin.setup and plugin.setup()
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
