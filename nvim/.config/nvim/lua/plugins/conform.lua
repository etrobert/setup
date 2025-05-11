-- Source: https://github.com/stevearc/conform.nvim

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo", "Format" },
	keys = {
		{
			"<leader>fm",
			function()
				require("conform").format({ async = true })
			end,
			mode = "",
			desc = "Format current buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			-- Use a sub-list to run only the first available formatter

			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },

			-- javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
			-- javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
			-- typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
			-- typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
			-- json = { "biome", "prettierd", "prettier", stop_after_first = true },

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
			timeout_ms = 1000,
			lsp_format = "fallback",
		},
	},
	config = function(_, opts)
		require("conform").setup(opts)

		-- Source: https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#format-command
		vim.api.nvim_create_user_command("Format", function(args)
			local range = nil
			if args.count ~= -1 then
				local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
				range = {
					start = { args.line1, 0 },
					["end"] = { args.line2, end_line:len() },
				}
			end
			require("conform").format({ async = true, lsp_format = "fallback", range = range })
		end, { range = true })
	end,
}
