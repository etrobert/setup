function DeleteOtherBuffers()
	local current_buf = vim.fn.bufnr("%")
	print(current_buf)
	vim.cmd("bufdo if bufnr() != " .. current_buf .. " | bd | endif")
end

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = function()
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

		return {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		}
	end,
}
