vim.pack.add({
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/saadparwaiz1/cmp_luasnip",
	"https://github.com/hrsh7th/cmp-path",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/hrsh7th/cmp-nvim-lsp-signature-help",
	"https://github.com/roobert/tailwindcss-colorizer-cmp.nvim",
	"https://github.com/rafamadriz/friendly-snippets",
	"https://github.com/hrsh7th/cmp-emoji",
})

-- See `:help cmp`
local cmp = require("cmp")
local luasnip = require("luasnip")
luasnip.config.setup({})

local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("*", { capabilities = lsp_capabilities })

require("luasnip.loaders.from_vscode").lazy_load()

-- Load custom snippets
require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/lua/snippets" })

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	completion = { completeopt = "menu,menuone,noinsert" },

	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},

	-- For an understanding of why these mappings were
	-- chosen, you will need to read `:help ins-completion`
	--
	-- No, but seriously. Please read `:help ins-completion`, it is really good!
	mapping = cmp.mapping.preset.insert({
		-- Select the [n]ext item
		["<C-n>"] = cmp.mapping.select_next_item(),
		-- Select the [p]revious item
		["<C-p>"] = cmp.mapping.select_prev_item(),

		-- Scroll the documentation window [b]ack / [f]orward
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),

		-- Accept ([y]es) the completion.
		--  This will auto-import if your LSP supports it.
		--  This will expand snippets if the LSP sent a snippet.
		["<C-y>"] = cmp.mapping.confirm({ select = true }),

		-- Manually trigger a completion from nvim-cmp.
		--  Generally you don't need this, because nvim-cmp will display
		--  completions whenever it has completion options available.
		["<C-Space>"] = cmp.mapping.complete({}),

		-- Think of <c-l> as moving to the right of your snippet expansion.
		--  So if you have a snippet that's like:
		--  function $name($args)
		--    $body
		--  end
		--
		-- <c-l> will move you to the right of each of the expansion locations.
		-- <c-h> is similar, except moving you backwards.
		["<C-l>"] = cmp.mapping(function()
			if luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			end
		end, { "i", "s" }),
		["<C-h>"] = cmp.mapping(function()
			if luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			end
		end, { "i", "s" }),

		-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
		--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
	}),
	sources = {
		{ name = "luasnip" },
		{ name = "emoji" },
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "nvim_lsp_signature_help" },
		{ name = "lazydev", group_index = 0 },
	},
	formatting = {
		format = require("tailwindcss-colorizer-cmp").formatter,
	},
})
