return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = {
		{
			"<leader>+",
			function()
				require("harpoon"):list():add()
			end,
		},
		{
			"<leader>h",
			function()
				local harpoon = require("harpoon")
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
		},
		{
			"<leader>1",
			function()
				require("harpoon"):list():select(1)
			end,
		},
		{
			"<leader>2",
			function()
				require("harpoon"):list():select(2)
			end,
		},
		{
			"<leader>3",
			function()
				require("harpoon"):list():select(3)
			end,
		},
		{
			"<leader>4",
			function()
				require("harpoon"):list():select(4)
			end,
		},
	},
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("harpoon"):setup()
	end,
}
