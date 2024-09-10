-- Source: https://github.com/stevearc/conform.nvim

return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			-- Use a sub-list to run only the first available formatter

			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },

			-- javascript = { "biome" },
			-- javascriptreact = { "biome" },
			-- typescript = { "biome" },
			-- typescriptreact = { "biome" },
			-- json = { "biome" },

			html = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },
			css = { "prettierd", "prettier", stop_after_first = true },

			swift = { "swiftformat" },

			sh = { "shfmt" },

			python = { "isort", "black" },

			rust = { "rustfmt" },
		},
		format_on_save = {
			-- These options will be passed to conform.format()
			timeout_ms = 500,
			lsp_format = "fallback",
		},
	},
}
