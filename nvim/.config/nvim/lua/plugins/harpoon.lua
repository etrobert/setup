vim.pack.add({
	-- Depencencies
	"https://github.com/nvim-lua/plenary.nvim",

	{
		src = "https://github.com/ThePrimeagen/harpoon",
		version = "harpoon2",
	},
})

require("harpoon"):setup()

vim.keymap.set("n", "<leader>+", function()
	require("harpoon"):list():add()
end)

vim.keymap.set("n", "<leader>q", function()
	local harpoon = require("harpoon")
	harpoon.ui:toggle_quick_menu(harpoon:list())
end)

vim.keymap.set("n", "<leader>1", function()
	require("harpoon"):list():select(1)
end)

vim.keymap.set("n", "<leader>2", function()
	require("harpoon"):list():select(2)
end)

vim.keymap.set("n", "<leader>3", function()
	require("harpoon"):list():select(3)
end)

vim.keymap.set("n", "<leader>4", function()
	require("harpoon"):list():select(4)
end)
