return {
	src = "https://github.com/windwp/nvim-ts-autotag",
	setup = function()
		require("nvim-ts-autotag").setup({
			opts = { enable_close = false, enable_rename = true, enable_close_on_slash = false },
		})
	end,
}
