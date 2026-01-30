vim.pack.add({
	"https://github.com/nvim-treesitter/nvim-treesitter",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
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
	require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
end)

-- require("nvim-treesitter.configs").setup({
-- 	modules = {},
-- 	ignore_install = {},
-- 	ensure_installed = {},
-- 	sync_install = false,
-- 	auto_install = true,
-- 	highlight = {
-- 		enable = true,
-- 		additional_vim_regex_highlighting = false,
-- 	},
-- 	textobjects = {
-- 		select = {
-- 			enable = true,
-- 			lookahead = true,
-- 			keymaps = {
-- 				["af"] = "@function.outer",
-- 				["if"] = "@function.inner",
-- 				["ac"] = "@comment.outer",
-- 				["ic"] = "@comment.inner",
-- 				["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
-- 			},
-- 			selection_modes = {
-- 				["@parameter.outer"] = "v",
-- 				["@function.outer"] = "V",
-- 				["@class.outer"] = "<c-v>",
-- 			},
-- 			include_surrounding_whitespace = true,
-- 		},
-- 		swap = {
-- 			enable = true,
-- 			swap_next = {
-- 				["<leader>a"] = "@parameter.inner",
-- 			},
-- 			swap_previous = {
-- 				["<leader>A"] = "@parameter.inner",
-- 			},
-- 		},
-- 		move = {
-- 			enable = true,
-- 			set_jumps = true,
-- 			goto_next_start = {
-- 				["]m"] = "@function.outer",
-- 				["]]"] = { query = "@class.outer", desc = "Next class start" },
-- 				["]o"] = "@loop.*",
-- 				["]s"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
-- 				["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
-- 			},
-- 			goto_next_end = {
-- 				["]M"] = "@function.outer",
-- 				["]["] = "@class.outer",
-- 			},
-- 			goto_previous_start = {
-- 				["[m"] = "@function.outer",
-- 				["[["] = "@class.outer",
-- 			},
-- 			goto_previous_end = {
-- 				["[M"] = "@function.outer",
-- 				["[]"] = "@class.outer",
-- 			},
-- 		},
-- 	},
-- })
--
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
-- vim.opt.foldlevelstart = 99
