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
	opts = {
		spec = {
			{ "<leader>pv", vim.cmd.Ex, desc = "File Explorer" },
			{ "<leader>n", vim.cmd.nohlsearch, desc = "Remove Search Highlight" },
			{ "<leader>b", group = "Buffer" },
			{ "<leader>bn", ":bnext<CR>", desc = "Next Buffer" },
			{ "<leader>bp", ":bprev<CR>", desc = "Previous Buffer" },
			{ "<leader>bd", ":bd<CR>", desc = "Delete Buffer" },
			{ "<leader>ba", ":bufdo bd<CR>", desc = "Delete All Buffers" },
			{ "<leader>bo", ":lua DeleteOtherBuffers()<CR>", desc = "Delete Other Buffers" },
		},
	},
}
