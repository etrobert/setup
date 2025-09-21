local M = {}

local function do_rename(old_name, new_name)
	vim.lsp.buf.rename(new_name)
	vim.notify("Renamed '" .. old_name .. "' to '" .. new_name .. "'", vim.log.levels.INFO)
end

local function get_surrounding_context(lines_before, lines_after)
	lines_before = lines_before or 5
	lines_after = lines_after or 5

	local current_line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")

	local start_line = math.max(1, current_line - lines_before)
	local end_line = math.min(total_lines, current_line + lines_after)

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	return lines
end

local function get_lsp_info()
	local params = vim.lsp.util.make_position_params(0, "utf-8")
	local hover_result = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 3000)

	local hover_info = nil

	if hover_result then
		for _, res in pairs(hover_result) do
			if res.result and res.result.contents then
				hover_info = res.result.contents
				break
			end
		end
	end

	return {
		hover = hover_info,
	}
end

function M.extract_context()
	local symbol = vim.fn.expand("<cword>")
	if symbol == "" then
		vim.notify("No symbol under cursor", vim.log.levels.WARN)
		return nil
	end

	local surrounding = get_surrounding_context()
	local filename = vim.fn.expand("%:t")
	local filetype = vim.bo.filetype
	local lsp_info = get_lsp_info()

	return {
		symbol = symbol,
		filename = filename,
		filetype = filetype,
		surrounding = surrounding,
		lsp_info = lsp_info,
	}
end

function M.call_openai_for_rename(context)
	if not os.getenv("OPENAI_API_KEY") or os.getenv("OPENAI_API_KEY") == "" then
		vim.notify("Missing OPENAI_API_KEY environment variable.", vim.log.levels.ERROR)
		return
	end

	-- Format LSP info for the prompt
	local lsp_context = ""
	if context.lsp_info.hover then
		local hover_text = ""
		if context.lsp_info.hover.value then
			hover_text = context.lsp_info.hover.value
		elseif context.lsp_info.hover[1] and context.lsp_info.hover[1].value then
			hover_text = context.lsp_info.hover[1].value
		end
		if hover_text ~= "" then
			lsp_context = lsp_context .. "Type information: \n" .. hover_text .. "\n"
		end
	end

	local prompt = string.format(
		[[
I need to rename the variable '%s' in this %s code. Please suggest a better name.

File: %s

%s
Code context:
```%s
%s
```

Instructions:
- Analyze how the variable is used
- Consider the type information if provided
- Follow %s naming conventions (camelCase for JS/TS, snake_case for Python, etc.)
- Suggest a descriptive name
- Respond with ONLY the suggested variable name (no explanation)
- If the current name is already good, respond with the current name
]],
		context.symbol,
		context.filetype,
		context.filename,
		lsp_context,
		context.filetype,
		table.concat(context.surrounding, "\n"),
		context.filetype
	)

	local system_message = [[
You are a code assistant that suggests better variable names.
Respond with ONLY a single variable name, nothing else - no keywords, no spaces, no assignment operators.
Follow the naming conventions of the programming language.
If the current name is already descriptive, return the current name.
Examples: "userCount", "totalPrice", "isValid"
]]

	-- Debugging
	vim.notify(prompt)

	return vim.system({
		"curl",
		"https://api.openai.com/v1/chat/completions",
		"-H",
		"Authorization: Bearer " .. os.getenv("OPENAI_API_KEY"),
		"-H",
		"Content-Type: application/json",
		"-d",
		vim.fn.json_encode({
			model = "gpt-4o-mini",
			messages = {
				{ role = "system", content = system_message },
				{ role = "user", content = prompt },
			},
			temperature = 0.3,
			max_tokens = 50,
		}),
	})
end

function M.parse_ai_response(response_text)
	local status, decoded = pcall(vim.json.decode, response_text)
	if not status then
		return nil, "Failed to decode JSON response"
	end

	if not decoded.choices or not decoded.choices[1] or not decoded.choices[1].message then
		return nil, "Invalid response structure"
	end

	local suggested_name = decoded.choices[1].message.content:gsub("^%s*", ""):gsub("%s*$", "")

	if suggested_name == "" then
		return nil, "Empty suggestion received"
	end

	return suggested_name, nil
end

function M.ai_rename()
	local context = M.extract_context()
	if not context then
		return
	end

	vim.notify("Getting AI suggestion for '" .. context.symbol .. "'...", vim.log.levels.INFO)

	local job = M.call_openai_for_rename(context)
	if not job then
		vim.notify("call_openai_for_rename returned nil", vim.log.levels.ERROR)
		return
	end

	local result = job:wait()

	if result.code ~= 0 then
		vim.notify("API request failed. Code: " .. result.code, vim.log.levels.ERROR)
		return
	end

	local suggested_name, err = M.parse_ai_response(result.stdout)
	if err then
		vim.notify("Error parsing AI response: " .. err, vim.log.levels.ERROR)
		return
	end

	if suggested_name == context.symbol then
		vim.notify("AI suggests keeping current name: " .. context.symbol, vim.log.levels.INFO)
		return
	end

	-- Confirm with user before renaming
	local confirm =
		vim.fn.confirm("Rename '" .. context.symbol .. "' to '" .. suggested_name .. "'?", "&Yes\n&No\n&Edit", 1)

	if confirm == 1 then
		do_rename(context.symbol, suggested_name)
	elseif confirm == 3 then
		local user_name = vim.fn.input("Enter name: ", suggested_name)
		if user_name ~= "" and user_name ~= context.symbol then
			do_rename(context.symbol, user_name)
		end
	end
end

function M.setup()
	vim.keymap.set("n", "gran", M.ai_rename, { desc = "AI-powered rename variable" })
end

return M
