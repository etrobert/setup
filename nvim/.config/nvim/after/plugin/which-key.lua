local wk = require("which-key")

wk.register({
	pv = { vim.cmd.Ex, "File Explorer" },
	n = { vim.cmd.nohlsearch, "Remove Search Highlight" },
	b = {
		name = "Buffer",
		n = { ":bnext<CR>", "Next Buffer" },
		p = { ":bprev<CR>", "Previous Buffer" },
		d = { ":bd<CR>", "Delete Buffer" },
		a = { ":bufdo bd<CR>", "Delete All Buffers" },
		o = { ":lua DeleteOtherBuffers()<CR>", "Delete Other Buffers" },
	},
}, { prefix = "<leader>" })

function DeleteOtherBuffers()
	local current_buf = vim.fn.bufnr("%")
	print(current_buf)
	vim.cmd("bufdo if bufnr() != " .. current_buf .. " | bd | endif")
end
