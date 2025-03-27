vim.g.mapleader = " "
vim.keymap.set("i", "jj", "<Esc>")

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "File Explorer" })
vim.keymap.set("n", "<leader>wd", function()
	vim.cmd("Ex " .. vim.fn.getcwd())
end, { desc = "File Explorer in Current Working Directory" })

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

-- Source: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html

-- note: diagnostics are not exclusive to lsp servers
-- so these can be global keybindings
vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float()
end)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)

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
		vim.keymap.set("n", "gi", function()
			vim.lsp.buf.implementation()
		end, opts)
		vim.keymap.set("n", "go", function()
			vim.lsp.buf.type_definition()
		end, opts)
		vim.keymap.set("n", "gr", function()
			vim.lsp.buf.references()
		end, opts)
		vim.keymap.set("n", "gs", function()
			vim.lsp.buf.signature_help()
		end, opts)
		vim.keymap.set("n", "<leader>vrn", function()
			vim.lsp.buf.rename()
		end, opts)
		vim.keymap.set("n", "<leader>vca", function()
			vim.lsp.buf.code_action()
		end, opts)
		vim.keymap.set({ "n", "x" }, "<F3>", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})
