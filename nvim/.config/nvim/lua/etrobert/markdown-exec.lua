local M = {}

-- Get information about the current markdown code block
function M.get_current_code_block()
	local line = vim.fn.line(".")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find code block boundaries
	local start_line, end_line, lang = nil, nil, nil

	-- Look backward for opening ```
	for i = line, 1, -1 do
		if lines[i]:match("^```(%w*)") then
			start_line = i
			lang = lines[i]:match("^```(%w+)")
			break
		end
	end

	-- Early return if no opening ``` found
	if not start_line then
		return nil
	end

	-- Look forward for closing ```
	for i = line, #lines do
		if lines[i]:match("^```%s*$") and i > start_line then
			end_line = i
			break
		end
	end

	-- Return nil if no closing ``` found
	if not end_line then
		return nil
	end

	-- Extract code lines
	local code_lines = {}
	for i = start_line + 1, end_line - 1 do
		table.insert(code_lines, lines[i])
	end

	return {
		language = lang,
		code = table.concat(code_lines, "\n"),
	}
end

-- Execute markdown code blocks
function M.execute_code_block()
	local block = M.get_current_code_block()

	if not block then
		vim.notify("No code block found at cursor", vim.log.levels.WARN)
		return
	end

	if not block.language then
		vim.notify("No language specified for code block", vim.log.levels.WARN)
		return
	end

	local output = ""
	if block.language == "bash" or block.language == "sh" then
		output = vim.fn.system("bash", block.code)
	elseif block.language == "javascript" or block.language == "js" then
		output = vim.fn.system("node -e " .. vim.fn.shellescape(block.code))
	elseif block.language == "python" then
		output = vim.fn.system("python3 -c " .. vim.fn.shellescape(block.code))
	else
		vim.notify("Unsupported language: " .. block.language, vim.log.levels.WARN)
		return
	end

	print(output)
end

function M.setup()
	vim.keymap.set("n", "<leader>ex", M.execute_code_block, { desc = "Execute markdown code block" })
end

return M
