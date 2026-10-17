vim.api.nvim_create_autocmd({ "TextYankPost", "TextPutPost" }, {
	desc = "Highlight when yanking or putting text",
	group = vim.api.nvim_create_augroup("hl-op", { clear = true }),
	callback = function()
		vim.hl.hl_op({ higroup = "Visual", timeout = 300 })
	end,
})
