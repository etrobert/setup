local wk = require("which-key")

wk.register({
	pv = { vim.cmd.Ex, "File Explorer" },
	n = { vim.cmd.nohlsearch, "Remove Search Highlight" },
}, { prefix = "<leader>" })
