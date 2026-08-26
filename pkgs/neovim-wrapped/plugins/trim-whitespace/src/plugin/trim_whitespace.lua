vim.api.nvim_create_autocmd("BufWritePre", {
	desc = "Remove trailing whitespace on save",
	group = vim.api.nvim_create_augroup("trim-whitespace", { clear = true }),
	command = [[%s/\s\+$//e]],
})
