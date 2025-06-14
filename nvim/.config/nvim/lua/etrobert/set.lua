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

vim.diagnostic.config({ virtual_text = true, jump = { float = true } })

vim.opt.cursorline = true

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	callback = function()
		vim.hl.on_yank({ higroup = "Visual", timeout = 300 })
	end,
})

vim.fn.matchadd("TrailingWhitespace", [[\s\+$]])
