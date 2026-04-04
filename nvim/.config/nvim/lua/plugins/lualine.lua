return {
	src = "https://github.com/nvim-lualine/lualine.nvim",
	setup = function()
		local relative_path = { "filename", path = 1 }
		require("lualine").setup({
			sections = { lualine_c = { relative_path }, lualine_x = { "filetype" } },
			inactive_sections = { lualine_c = { relative_path } },
		})
	end,
}
