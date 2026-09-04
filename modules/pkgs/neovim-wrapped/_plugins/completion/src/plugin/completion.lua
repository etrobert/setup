-- Per buffer: 'complete' also drives i_CTRL-N, which is all a buffer without a
-- server has. Where there is one, its default sources only duplicate LSP items.
local group = vim.api.nvim_create_augroup("completion", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if not client:supports_method("textDocument/completion", event.buf) then
			return
		end
		-- Prose: marksman and texlab complete links and commands, never words, so
		-- the menu would sit empty while i_CTRL-N went missing.
		if vim.list_contains({ "markdown", "tex", "plaintex", "bib" }, vim.bo[event.buf].filetype) then
			return
		end
		vim.bo[event.buf].complete = "o"
		vim.bo[event.buf].completeopt = vim.go.completeopt .. ",menuone,noinsert,fuzzy"
		-- An item is always selected, so a server's commit characters would accept
		-- it mid-word: typing `const shou = 1;` lands as `const shou = Int16Array;`.
		vim.lsp.completion.enable(true, client.id, event.buf, { commit_characters = false })
		-- Same cause: <CR> would accept the selected item instead of breaking the
		-- line. i_CTRL-X_CTRL-Z closes the menu keeping whatever is in the buffer,
		-- so an item picked with i_CTRL-N survives.
		vim.keymap.set("i", "<CR>", function()
			return vim.fn.pumvisible() == 1 and "<C-x><C-z><CR>" or "<CR>"
		end, { expr = true, buffer = event.buf, desc = "Line break, dismissing the completion menu" })
	end,
})

-- Only after a keyword character or a dot. Elsewhere a server answers with its
-- whole scope, so the menu would open on ~1000 items at every space and brace.
vim.api.nvim_create_autocmd("InsertCharPre", {
	group = group,
	callback = function()
		if vim.bo.complete == "o" then
			vim.bo.autocomplete = vim.v.char == "." or vim.fn.match(vim.v.char, "\\k") >= 0
		end
	end,
})

-- <Tab> accepts inline completion, so snippets jump on <C-l>/<C-h>.
vim.keymap.set({ "i", "s" }, "<C-l>", function()
	vim.snippet.jump(1)
end, { desc = "Next snippet placeholder" })

vim.keymap.set({ "i", "s" }, "<C-h>", function()
	vim.snippet.jump(-1)
end, { desc = "Previous snippet placeholder" })
