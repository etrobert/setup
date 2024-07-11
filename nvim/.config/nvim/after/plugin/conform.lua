-- Source: https://github.com/stevearc/conform.nvim

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- Use a sub-list to run only the first available formatter

		-- javascript = { { "prettierd", "prettier" } },
		-- javascriptreact = { { "prettierd", "prettier" } },
		-- typescript = { { "prettierd", "prettier" } },
		-- typescriptreact = { { "prettierd", "prettier" } },
		-- json = { { "prettierd", "prettier" } },
		-- html = { { "prettierd", "prettier" } },
		-- markdown = { { "prettierd", "prettier" } },

		javascript = { "biome" },
		javascriptreact = { "biome" },
		typescript = { "biome" },
		typescriptreact = { "biome" },
		json = { "biome" },
		html = { "biome" },
		markdown = { "biome" },

		swift = { "swiftformat" },
	},
	format_on_save = {
		-- These options will be passed to conform.format()
		timeout_ms = 500,
		lsp_fallback = true,
	},
})
