-- The clipboard provider writes to this machine; over SSH the terminal is on another
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		if vim.v.event.regname == "" then
			require("vim.ui.clipboard.osc52").copy("+")(vim.v.event.regcontents)
		end
	end,
})
