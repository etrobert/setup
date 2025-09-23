vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		json = { "prettierd", "prettier", stop_after_first = true },
		jsonc = { "prettierd", "prettier", stop_after_first = true },
		html = { "prettierd", "prettier", stop_after_first = true },
		markdown = { "prettierd", "prettier", stop_after_first = true },
		css = { "prettierd", "prettier", stop_after_first = true },
		swift = { "swiftformat" },
		sh = { "shfmt" },
		fish = { "fish_indent" },
		rust = { "rustfmt" },
	},
	format_on_save = {
		timeout_ms = 1000,
		lsp_format = "fallback",
	},
})

vim.keymap.set("", "<leader>fm", function()
	require("conform").format({ async = true })
end, { desc = "Format current buffer" })

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

local aug = vim.api.nvim_create_augroup("ConformFidgetProgress", { clear = true })
local handles = {}

local function format_display_name(bufnr)
	local filename = vim.api.nvim_buf_get_name(bufnr)
	if filename == "" then
		return string.format("[buffer %d]", bufnr)
	end
	return vim.fn.fnamemodify(filename, ":t")
end

vim.api.nvim_create_autocmd("User", {
	group = aug,
	pattern = "ConformFormatPre",
	callback = function(event)
		local formatter = event.data.formatter.name
		handles[event.buf] = require("fidget.progress").handle.create({
			lsp_client = { name = formatter },
			title = string.format("Formatting %s", format_display_name(event.buf)),
		})
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = aug,
	pattern = "ConformFormatPost",
	callback = function(event)
		local handle = handles[event.buf]
		if not handle then
			return
		end
		handles[event.buf] = nil
		local err = event.data and event.data.err
		if err then
			handle:report({ message = "Failed" })
		end
		handle:finish()
	end,
})
