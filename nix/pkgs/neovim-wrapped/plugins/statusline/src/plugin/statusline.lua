vim.opt.showmode = false
vim.opt.statusline = "%!v:lua.require('statusline').render()"

vim.api.nvim_create_autocmd("ModeChanged", {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})
