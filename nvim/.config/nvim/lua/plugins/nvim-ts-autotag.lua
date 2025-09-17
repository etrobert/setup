vim.pack.add({ "https://github.com/windwp/nvim-ts-autotag" })

-- Comes from the doc
---@diagnostic disable-next-line: missing-fields
require("nvim-ts-autotag").setup({
	opts = {
		enable_close = false,
		enable_rename = true,
		enable_close_on_slash = false,
	},
})
