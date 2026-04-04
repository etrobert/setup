return {
	src = "https://github.com/catppuccin/nvim",
	name = "catppuccin",
	setup = function()
		if os.getenv("WAYLAND_DISPLAY") or vim.fn.has("mac") == 1 then
			-- Graphical session (Wayland on Linux or macOS)
			require("catppuccin").setup({ float = { transparent = true, solid = false } })
			vim.cmd("colorscheme catppuccin-macchiato")
			-- else we're in a tty, using default theme
		end
	end,
}
