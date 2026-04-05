-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.cmd.packadd("nvim.undotree")

require("snacks").setup({ image = {} })

require("plugins.harpoon")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.cmp")

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
