-- Prints line numbers
vim.opt.number = true

-- Highlights the column 81
vim.opt.colorcolumn = "81"

vim.opt.guicursor = ""

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

vim.opt.scrolloff = 3

vim.opt.wrap = false

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.clipboard:append("unnamedplus")

vim.opt.backspace = "eol,indent"

vim.diagnostic.config({
	virtual_text = true,
	jump = {
		on_jump = function()
			vim.diagnostic.open_float()
		end,
	},
})

vim.opt.cursorline = true

-- Decrease update time
vim.o.updatetime = 250

-- Highlight when yanking text
---@diagnostic disable-next-line: param-type-mismatch
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	callback = function()
		vim.hl.on_yank({ higroup = "Visual", timeout = 300 })
	end,
})

-- vim.opt.list = true
-- vim.opt.listchars = { tab = "» ", extends = "›", precedes = "‹", nbsp = "·", trail = "·" }

-- Disable because super buggy
-- vim.lsp.inline_completion.enable()

-- don't give the intro message when starting Vim, see :intro
-- vim.opt.shortmess:append("I")

vim.lsp.config["knip_lsp"] = {
	cmd = { "node", "/Users/etiennerobert/work/knip-lsp/out/main.js", "--stdio" },
	filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json" },
	root_markers = { ".git", "package.json" },
}

vim.lsp.enable({
	"bashls",
	"eslint",
	"tailwindcss",
	"ts_ls",
	"rust_analyzer",
	"gopls",
	"lua_ls",
	"copilot",
	"knip_lsp",
})

vim.o.winborder = "rounded"
