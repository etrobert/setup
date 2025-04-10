local M = {}

-- Function to get git information
local function get_git_info()
	local git_info = {}

	return git_info
end

-- Function to create a welcome screen
function M.setup()
	-- Create welcome content
	local content = { "" }

	-- Get raw git status
	local status = vim.fn.system("git status --branch --short 2>/dev/null")

	if status ~= "" then
		table.insert(content, "  Git Status:")
		table.insert(
			content,
			"  ────────────────────────────────────────────────────────────────────────────"
		)
		
		for line in status:gmatch("[^\r\n]+") do
			table.insert(content, "  " .. line)
		end
	end

	local content_length = #content

	-- Create a new buffer for the welcome screen
	local buf = vim.api.nvim_create_buf(false, true)
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- Calculate dimensions for the welcome window
	local win_width = 80
	local win_height = #content + 1
	local col = math.floor((width - win_width) / 2)
	local row = math.floor((height - win_height) / 2)

	-- Create the window
	local opts = {
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "filetype", "welcome")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "termguicolors", true)

	-- Set the content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

	-- Set buffer as non-modifiable
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Set keymap to close the welcome screen
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, noremap = true })

	-- Set keymap to close with 'q' key
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, noremap = true })

	-- Set cursor to the top
	vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

return M
