vim.pack.add({
	"https://github.com/nvim-treesitter/nvim-treesitter",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main", -- TODO: Remove version = "main" when it becomes the default branch
	},
})

require("nvim-treesitter").install({
	"bash",
	"c",
	"diff",
	"html",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"query",
	"vim",
	"vimdoc",
	"javascript",
	"typescript",
	"json",
	"go",
	"rust",
})

require("nvim-treesitter-textobjects").setup({
	select = {
		-- Automatically jump forward to textobj, similar to targets.vim
		lookahead = true,

		selection_modes = {
			-- You can choose the select mode (default is charwise 'v')
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * method: eg 'v' or 'o'
			-- and should return the mode ('v', 'V', or '<c-v>') or a table
			-- mapping query_strings to modes.
			-- ["@parameter.outer"] = "v", -- charwise
			["@function.outer"] = "V", -- linewise
			-- ['@class.outer'] = '<c-v>', -- blockwise
		},

		-- If you set this to `true` (default is `false`) then any textobject is
		-- extended to include preceding or succeeding whitespace. Succeeding
		-- whitespace has priority in order to act similarly to eg the built-in
		-- `ap`.
		--
		-- Can also be a function which gets passed a table with the keys
		-- * query_string: eg '@function.inner'
		-- * selection_mode: eg 'v'
		-- and should return true of false
		include_surrounding_whitespace = false,
	},
})

local select = require("nvim-treesitter-textobjects.select")

vim.keymap.set({ "x", "o" }, "af", function()
	select.select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "if", function()
	select.select_textobject("@function.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ac", function()
	select.select_textobject("@comment.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ic", function()
	select.select_textobject("@comment.inner", "textobjects")
end)
-- You can also use captures from other query groups like `locals.scm`
vim.keymap.set({ "x", "o" }, "as", function()
	select.select_textobject("@local.scope", "locals")
end)

local swap = require("nvim-treesitter-textobjects.swap")

-- keymaps
vim.keymap.set("n", "<leader>a", function()
	swap.swap_next("@parameter.inner")
end)
vim.keymap.set("n", "<leader>A", function()
	swap.swap_previous("@parameter.outer")
end)

-- configuration
require("nvim-treesitter-textobjects").setup({
	move = {
		-- whether to set jumps in the jumplist
		set_jumps = true,
	},
})

local move = require("nvim-treesitter-textobjects.move")

-- keymaps
-- You can use the capture groups defined in `textobjects.scm`
vim.keymap.set({ "n", "x", "o" }, "]m", function()
	move.goto_next_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "]]", function()
	move.goto_next_start("@class.outer", "textobjects")
end)
-- You can also pass a list to group multiple queries.
vim.keymap.set({ "n", "x", "o" }, "]o", function()
	move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
end)
-- You can also use captures from other query groups like `locals.scm` or `folds.scm`
vim.keymap.set({ "n", "x", "o" }, "]s", function()
	move.goto_next_start("@local.scope", "locals")
end)
vim.keymap.set({ "n", "x", "o" }, "]z", function()
	move.goto_next_start("@fold", "folds")
end)

vim.keymap.set({ "n", "x", "o" }, "]M", function()
	move.goto_next_end("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "][", function()
	move.goto_next_end("@class.outer", "textobjects")
end)

vim.keymap.set({ "n", "x", "o" }, "[m", function()
	move.goto_previous_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[[", function()
	move.goto_previous_start("@class.outer", "textobjects")
end)

vim.keymap.set({ "n", "x", "o" }, "[M", function()
	move.goto_previous_end("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[]", function()
	move.goto_previous_end("@class.outer", "textobjects")
end)

-- Go to either the start or the end, whichever is closer.
-- Use if you want more granular movements
vim.keymap.set({ "n", "x", "o" }, "]d", function()
	move.goto_next("@conditional.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[d", function()
	move.goto_previous("@conditional.outer", "textobjects")
end)

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99
