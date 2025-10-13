vim.g.mapleader = " "
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "-", vim.cmd.Ex, { desc = "Open netrw file explorer" })

vim.keymap.set("n", "<leader>n", vim.cmd.nohlsearch, { desc = "Remove Search Highlight" })

-- Buffers

local function delete_other_buffers()
	local current_buf = vim.fn.bufnr("%")
	vim.cmd("bufdo if bufnr() != " .. current_buf .. " | bd | endif")
end

-- ]b is mapped to bnext
-- [b is mapped to bprev
vim.keymap.set("n", "<leader>bd", ":b#|bd#<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>ba", ":%bd<CR>", { desc = "Delete All Buffers" })
vim.keymap.set("n", "<leader>bo", delete_other_buffers, { desc = "Delete Other Buffers" })

function DeleteCurrentFile()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Can't find filename to delete", vim.log.levels.WARN)
		return
	end
	if vim.fn.delete(file) == -1 then
		vim.notify("File " .. file .. " could not be deleted", vim.log.levels.ERROR)
		return
	end
	vim.cmd("bd")
	vim.notify("Deleted " .. file, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>rm", DeleteCurrentFile, { desc = "Delete current file" })

-- See :help lsp-defaults
-- These GLOBAL keymaps are created unconditionally when Nvim starts:
-- - "CTRL-]" is mapped in Normal mode to go to definition
-- - "grn" is mapped in Normal mode to |vim.lsp.buf.rename()|
-- - "gra" is mapped in Normal and Visual mode to |vim.lsp.buf.code_action()|
-- - "grr" is mapped in Normal mode to |vim.lsp.buf.references()|
-- - "gri" is mapped in Normal mode to |vim.lsp.buf.implementation()|
-- - "grt" is mapped in Normal mode to |vim.lsp.buf.type_definition()|
-- - "gO" is mapped in Normal mode to |vim.lsp.buf.document_symbol()|
-- - CTRL-S is mapped in Insert mode to |vim.lsp.buf.signature_help()|
-- - "an" and "in" are mapped in Visual mode to outer and inner incremental
--  selections, respectively, using |vim.lsp.buf.selection_range()|

-- Override default grr to use Telescope LSP references
-- Source: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-telescope-references", { clear = true }),
	callback = function(args)
		vim.keymap.set("n", "grr", function()
			require("telescope.builtin").lsp_references()
		end, { buffer = args.buf, desc = "LSP References (Telescope)" })
	end,
})

vim.keymap.set("n", "grq", function()
	local diagnostics = vim.diagnostic.get()
	local qf_items = vim.diagnostic.toqflist(diagnostics)

	-- Add source prefix to each item
	for i, diag in ipairs(diagnostics) do
		if diag.source then
			qf_items[i].text = "[" .. diag.source .. "] " .. qf_items[i].text
		end
	end

	vim.fn.setqflist(qf_items)
	vim.cmd("copen")
end, { desc = "Diagnostics to quickfix list" })

-- See :help vim.lsp.inline_completion.get()
vim.keymap.set("i", "<Tab>", function()
	if not vim.lsp.inline_completion.get() then
		return "<Tab>"
	end
end, {
	expr = true,
	replace_keycodes = true,
	desc = "Get the current inline completion",
})

function CopyFileLine()
	local file_line = vim.fn.expand("%") .. ":" .. vim.fn.line(".")

	vim.fn.setreg("+", file_line)
	vim.notify("Copied: " .. file_line)
end

vim.api.nvim_create_user_command("CopyFileLine", CopyFileLine, {})
vim.keymap.set("n", "<leader>y", CopyFileLine, { desc = "Copy file and line number" })

-- Close all floating windows
vim.api.nvim_create_user_command("CloseFloats", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= "" then
			vim.api.nvim_win_close(win, false)
		end
	end
end, { desc = "Close all floating windows" })

-- Auto-remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("trim-whitespace", { clear = true }),
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
