-- Function to center the text
local function center_text_horizontally(text)
	-- local term_width = vim.opt.columns:get() -- Get terminal width
	local term_width = 80 -- Get terminal width
	local centered_lines = {}

	for _, line in ipairs(text) do
		local padding = math.max(0, (term_width - #line) / 2) -- Calculate padding
		table.insert(centered_lines, string.rep(" ", padding) .. line) -- Add padding
	end

	return centered_lines
end

local function center_text_vertically(text)
	local term_height = vim.opt.lines:get() -- Get terminal height
	local total_lines = #text
	local empty_lines_before = math.max(0, math.floor((term_height - total_lines) / 2))

	-- Create a new table with empty lines for vertical centering
	local final_lines = {}
	for _ = 1, empty_lines_before do
		table.insert(final_lines, "") -- Add empty lines
	end

	-- Add the centered lines
	for _, line in ipairs(text) do
		table.insert(final_lines, line)
	end

	return final_lines
end

local function center_text(text)
	local centered_horizontally = center_text_horizontally(text)
	local centered_vertically = center_text_vertically(centered_horizontally)

	return centered_vertically
end

-- Function to display the custom message or dashboard
local function custom_startup_screen()
	if vim.fn.argc() == 0 then -- Only show if no file is opened
		vim.cmd("enew") -- Create a new empty buffer
		vim.bo.buflisted = false -- Hide buffer from buffer list
		vim.bo.buftype = "nofile" -- No file associated with this buffer
		vim.bo.swapfile = false -- No swap file
		vim.bo.bufhidden = "wipe" -- Wipe buffer when hidden

		-- Define your custom message
		local lines = {
			"Neovim",
		}

		local centered_lines = center_text(lines) -- Center the text

		-- Insert the lines into the buffer
		vim.api.nvim_buf_set_lines(0, 0, -1, false, centered_lines)

		vim.bo.modifiable = false -- Make buffer non-editable
	end
end

-- Run the custom startup screen function when Neovim starts
vim.api.nvim_create_autocmd("VimEnter", { callback = custom_startup_screen })
