vim.g.mapleader = " "
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "-", vim.cmd.Ex, { desc = "Open netrw file explorer" })

vim.keymap.set("n", "<leader>n", vim.cmd.nohlsearch, { desc = "Remove Search Highlight" })

-- Buffers

local function delete_all_buffers()
	vim.cmd.bufdo("bd")
end

local function delete_other_buffers()
	local current_buf = vim.fn.bufnr("%")
	vim.cmd("bufdo if bufnr() != " .. current_buf .. " | bd | endif")
end

vim.keymap.set("n", "<leader>bn", vim.cmd.bnext, { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bp", vim.cmd.bprev, { desc = "Previous Buffer" })
vim.keymap.set("n", "<leader>bd", vim.cmd.bd, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>ba", delete_all_buffers, { desc = "Delete All Buffers" })
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

-- Source: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	callback = function()
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
		vim.keymap.set("i", "<Tab>", function()
			vim.lsp.inline_completion.get()
		end)
	end,
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
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
