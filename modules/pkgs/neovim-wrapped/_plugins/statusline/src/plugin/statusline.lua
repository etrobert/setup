vim.opt.showmode = false
vim.opt.statusline = "%!v:lua.require('statusline').render()"

vim.api.nvim_create_autocmd("ModeChanged", {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

-- Redraw when gitsigns updates so branch changes are reflected immediately
-- rather than waiting for the next cursor move or mode change.
vim.api.nvim_create_autocmd("User", {
	pattern = "GitSignsUpdate",
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

-- Redraw after fugitive git operations (commit, add, reset, etc.)
vim.api.nvim_create_autocmd("User", {
	pattern = "FugitiveChanged",
	callback = function()
		require("statusline.ahead_behind").invalidate()
		vim.cmd.redrawstatus()
	end,
})

-- Redraw when diagnostics change so counts update without waiting for cursor move.
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})
