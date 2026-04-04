return {
	src = "https://github.com/rcarriga/nvim-notify",
	setup = function()
		require("notify").setup({ merge_duplicates = false, background_colour = "#25273A" })
		vim.notify = require("notify")
	end,
}
