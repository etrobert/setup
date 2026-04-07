-- Record startup time as early as possible
vim.g.start_time = vim.fn.reltime()

vim.loader.enable()

require("etrobert")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

vim.opt.autocomplete = true
vim.opt.completeopt = { "menuone", "menu", "popup", "noinsert" }

vim.cmd.packadd("nvim.undotree")

-- TODO: Fix this is injected before plugins are loaded
-- require("etrobert.startup_banner").setup()
