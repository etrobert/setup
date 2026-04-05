-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.cmd.packadd("nvim.undotree")

if os.getenv("WAYLAND_DISPLAY") or vim.fn.has("mac") == 1 then
	-- Graphical session (Wayland on Linux or macOS)
	require("catppuccin").setup({ float = { transparent = true, solid = false } })
	vim.cmd("colorscheme catppuccin-macchiato")
	-- else we're in a tty, using default theme
end

require("notify").setup({ merge_duplicates = false, background_colour = "#25273A" })
vim.notify = require("notify")

require("treesj").setup({ max_join_length = 500 })

require("snacks").setup({ image = {} })

require("which-key").setup({
	spec = {
		{ "<leader>b", group = "Buffer" },
		{ "<leader>g", group = "Telescope Git" },
		{ "<leader>f", group = "Telescope Files" },
		{ "<leader>o", group = "Octo" },
	},
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
require("plugins.octo")

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

-- require("hardtime").setup()

require("etrobert.startup_banner").setup()
