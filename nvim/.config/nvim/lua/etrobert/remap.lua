vim.g.mapleader = " "
vim.keymap.set("i", "jj", "<Esc>")

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
		vim.keymap.set("n", "go", function()
			vim.lsp.buf.type_definition()
		end, opts)
		vim.keymap.set("n", "gs", function()
			vim.lsp.buf.signature_help()
		end, opts)
		vim.keymap.set({ "n", "x" }, "<F3>", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

function OpenPluginGithub()
	local line = vim.fn.getline(".")
	local repo = line:match('"([^/]+/[^"]+)"')

	if repo then
		local url = "https://github.com/" .. repo
		vim.fn.system("open " .. url)
		print("Opening: " .. url)
	else
		print("No GitHub repository found on current line")
	end
end

-- Create command and mapping
vim.cmd("command OpenPluginGithub lua OpenPluginGithub()")
vim.keymap.set("n", "<leader>pg", OpenPluginGithub, { desc = "Open plugin GitHub page" })
