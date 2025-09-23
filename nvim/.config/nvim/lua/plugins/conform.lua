vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

local conform = require("conform")
local fidget = require("fidget")

conform.setup({
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
	format_on_save = function(bufnr)
		local formatters = conform.list_formatters(bufnr)
		if #formatters == 0 then
			return
		end

		local formatter_names = {}
		for _, formatter in ipairs(formatters) do
			table.insert(formatter_names, formatter.name)
		end
		local formatter_list = table.concat(formatter_names, ", ")

		local progress = fidget.progress.handle.create({
			title = "Auto-formatting",
			message = "Running " .. formatter_list,
			lsp_client = { name = "conform.nvim" },
		})

		return {
			timeout_ms = 1000,
			lsp_format = "fallback",
			callback = function(err)
				if err then
					progress:finish()
					fidget.notify("Auto-format failed: " .. err, vim.log.levels.ERROR)
				else
					progress:report({ message = "Complete" })
					progress:finish()
				end
			end,
		}
	end,
})

-- Custom format function with fidget progress notifications
local function format_with_progress(opts)
	opts = opts or {}
	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype
	local formatters = conform.list_formatters(bufnr)

	if #formatters == 0 then
		fidget.notify("No formatters available for " .. filetype, vim.log.levels.WARN)
		return
	end

	local formatter_names = {}
	for _, formatter in ipairs(formatters) do
		table.insert(formatter_names, formatter.name)
	end
	local formatter_list = table.concat(formatter_names, ", ")

	local progress = fidget.progress.handle.create({
		title = "Formatting",
		message = "Running " .. formatter_list,
		lsp_client = { name = "conform.nvim" },
	})

	opts.callback = function(err)
		if err then
			progress:finish()
			fidget.notify("Format failed: " .. err, vim.log.levels.ERROR)
		else
			progress:report({ message = "Complete" })
			progress:finish()
			fidget.notify("Formatted with " .. formatter_list, vim.log.levels.INFO)
		end
	end

	conform.format(opts)
end

vim.keymap.set("", "<leader>fm", function()
	format_with_progress({ async = true })
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
	format_with_progress({ async = true, lsp_format = "fallback", range = range })
end, { range = true })
