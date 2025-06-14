local M = {}

local function append(buf, text)
	local last_line = vim.api.nvim_buf_get_lines(buf, -2, -1, false)[1]

	local lines = vim.split(text, "\n")
	lines[1] = last_line .. lines[1]

	vim.api.nvim_buf_set_lines(buf, -2, -1, false, lines)
end

local function create_side_buffer()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	return buf
end

local function get_buffer_content(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	return table.concat(lines, "\n")
end

---@param opts { args: string }
function M.ask(opts)
	if not os.getenv("OPENAI_API_KEY") or os.getenv("OPENAI_API_KEY") == "" then
		vim.notify("Missing OPENAI_API_KEY environment variable.", vim.log.levels.ERROR)
		return
	end

	local current_file = vim.api.nvim_get_current_buf()

	local buf = create_side_buffer()

	local user_message = opts.args ~= "" and opts.args or vim.fn.input("Prompt: ")
	local filename = vim.api.nvim_buf_get_name(current_file)
	filename = vim.fn.fnamemodify(filename, ":.")
	local buffer_content = get_buffer_content(current_file)
	local diff = vim.fn.system("git diff")
	local prompt = ([[
%s

Below is some context automatically added:

git diff:

%s

Current file (%s):

%s
]]):format(user_message, diff, filename, buffer_content)

	local system_message = [[
You are a code assistant.
Keep your response line length under 80 characters,
break lines with a newline if needed.
Use markdown formatting.
]]

	local job = vim.system({
		"curl",
		"https://api.openai.com/v1/chat/completions",
		"-N",
		"-H",
		"Authorization: Bearer " .. os.getenv("OPENAI_API_KEY"),
		"-H",
		"Content-Type: application/json",
		"-d",
		vim.fn.json_encode({
			model = "gpt-4.1",
			messages = {
				{ role = "system", content = system_message },
				{ role = "user", content = prompt },
			},
			stream = true,
		}),
	}, {
		stdout = function(_, data)
			if not data then
				return
			end
			local lines = vim.split(data, "\n")
			for _, line in ipairs(lines) do
				if line == "" then
					goto continue
				end
				line = line:gsub("^data:%s*", "")
				if line == "[DONE]" then
					goto continue
				end
				local status, decoded_data = pcall(vim.json.decode, line)
				if not status then
					vim.notify("Error decoding JSON: " .. decoded_data, vim.log.levels.ERROR)
					goto continue
				end
				local content = decoded_data.choices[1].delta.content
				if not content then
					goto continue
				end
				vim.schedule(function()
					append(buf, content)
				end)
				::continue::
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			if job then
				job:kill("sigterm")
			end
		end,
	})
end

function M.setup()
	vim.api.nvim_create_user_command("Ask", M.ask, { nargs = "*" })
end

return M
