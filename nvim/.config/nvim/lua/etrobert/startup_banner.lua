local M = {}

local function create_banner(message)
	local lines = { "", message, "" }
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end
	width = math.max(width + 4, 30)
	local height = #lines

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local row = math.floor((vim.o.lines - height) / 2) - 1
	row = math.max(row, 0)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "none",
		focusable = false,
	})
	vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = win })

	local function close_banner()
		if win and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		win = nil

		if buf and vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		buf = nil
	end

	vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufReadPost" }, {
		once = true,
		callback = close_banner,
	})
end

local function on_vim_enter()
	local elapsed = vim.fn.reltimefloat(vim.fn.reltime(vim.g.start_time)) * 1000
	local message = string.format("⚡ Neovim loaded in %.1fms", elapsed)

	local show_banner = vim.fn.argc() == 0
		and vim.api.nvim_buf_get_name(0) == ""
		and vim.bo.filetype == ""
		and vim.api.nvim_buf_line_count(0) == 1
		and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""

	if show_banner then
		create_banner(message)
	else
		vim.api.nvim_echo({ { message, "Title" } }, false, {})
	end
end

function M.setup()
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = on_vim_enter,
	})
end

return M
