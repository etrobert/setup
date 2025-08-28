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
	callback = function(event)
		local opts = { buffer = event.buf }

		-- these will be buffer-local keybindings
		-- because they only work if you have an active language server

		vim.keymap.set("n", "gd", function()
			vim.lsp.buf.definition()
		end, opts)
		vim.keymap.set("n", "gD", function()
			vim.lsp.buf.declaration()
		end, opts)
		-- These GLOBAL keymaps are created unconditionally when Nvim starts:
		-- - "grn" is mapped in Normal mode to |vim.lsp.buf.rename()|
		-- - "gra" is mapped in Normal and Visual mode to |vim.lsp.buf.code_action()|
		-- - "grr" is mapped in Normal mode to |vim.lsp.buf.references()|
		-- - "gri" is mapped in Normal mode to |vim.lsp.buf.implementation()|
		-- - "grt" is mapped in Normal mode to |vim.lsp.buf.type_definition()|
		-- - "gO" is mapped in Normal mode to |vim.lsp.buf.document_symbol()|
		-- - CTRL-S is mapped in Insert mode to |vim.lsp.buf.signature_help()|
		-- - "an" and "in" are mapped in Visual mode to outer and inner incremental
		--  selections, respectively, using |vim.lsp.buf.selection_range()|
		vim.keymap.set({ "n", "x" }, "<F3>", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
		vim.keymap.set("i", "<Tab>", function()
			vim.lsp.inline_completion.get()
		end)
	end,
})

function OpenPluginGithub()
	local line = vim.fn.getline(".")
	local repo = line:match('"([^/]+/[^"]+)"')

	if repo then
		local url = "https://github.com/" .. repo
		vim.fn.system("open " .. url)
		vim.notify("Opening: " .. url, vim.log.levels.INFO)
	else
		vim.notify("No GitHub repository found on current line", vim.log.levels.WARN)
	end
end

-- Create command and mapping
vim.api.nvim_create_user_command("OpenPluginGithub", OpenPluginGithub, {})
vim.keymap.set("n", "<leader>pg", OpenPluginGithub, { desc = "Open plugin GitHub page" })

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
