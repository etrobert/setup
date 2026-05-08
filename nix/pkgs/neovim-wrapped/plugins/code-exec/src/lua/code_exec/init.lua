local M = {}

-- Get visual selection content
function M.get_visual_selection()
	-- Use last visual selection marks since visual mode exits before this is called
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2]
	local end_line = end_pos[2]

	-- Get full lines in selection
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	return table.concat(lines, "\n")
end

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

	M.execute_by_language(block.code, block.language)
end

-- Execute visual selection
function M.execute_visual_selection()
	local code = M.get_visual_selection()
	local language = vim.bo.filetype

	if not code then
		vim.notify("No visual selection found", vim.log.levels.WARN)
		return
	end

	if not language then
		vim.notify("No language specified for code execution", vim.log.levels.WARN)
		return
	end

	M.execute_by_language(code, language)
end

-- Execute code by language
function M.execute_by_language(code, language)
	local output = ""

	if language == "bash" or language == "sh" then
		output = vim.fn.system("bash", code)
	elseif language == "javascript" or language == "js" or language == "javascriptreact" or language == "jsx" then
		output = vim.fn.system("node -e " .. vim.fn.shellescape(code))
	elseif language == "typescript" or language == "ts" or language == "typescriptreact" or language == "tsx" then
		output = vim.fn.system("bun -e " .. vim.fn.shellescape(code))
	elseif language == "python" then
		output = vim.fn.system("python3 -c " .. vim.fn.shellescape(code))
	else
		vim.notify("Unsupported language: " .. language, vim.log.levels.WARN)
		return
	end

	print(output)
end

function M.setup()
	vim.keymap.set("n", "<leader>ex", M.execute_code_block, { desc = "Execute code block" })
	vim.keymap.set(
		"v",
		"<leader>ex",
		":lua require('etrobert.code-exec').execute_visual_selection()<CR>",
		{ desc = "Execute visual selection" }
	)
end

return M
