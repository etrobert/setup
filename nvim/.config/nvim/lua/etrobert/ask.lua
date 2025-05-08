local M = {}

---@param opts { args: string }
function M.ask(opts)
	if not os.getenv("OPENAI_API_KEY") or os.getenv("OPENAI_API_KEY") == "" then
		vim.notify("Missing OPENAI_API_KEY environment variable.", vim.log.levels.ERROR)
		return
	end

	local curl = require("plenary.curl")
	local user_message = opts.args ~= "" and opts.args or vim.fn.input("Prompt: ")
	local filename = vim.api.nvim_buf_get_name(0)
	filename = vim.fn.fnamemodify(filename, ":.")
	local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	local prompt = string.format("%s\n\nCurrent file (%s):\n\n%s", user_message, filename, buffer_content)

	local response = curl.post("https://api.openai.com/v1/chat/completions", {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. os.getenv("OPENAI_API_KEY"),
		},
		body = vim.fn.json_encode({
			model = "gpt-4.1",
			messages = {
				{
					role = "system",
					content = [[
You are a code assistant.
Keep your response line length under 80 characters,
break lines with a newline if needed.
Use markdown formatting.
]],
				},
				{ role = "user", content = prompt },
			},
			max_tokens = 1000,
		}),
		timeout = 20000,
	})

	if response.status ~= 200 then
		vim.notify("Error: " .. response.status .. " - " .. response.body, vim.log.levels.ERROR)
		return
	end

	local output = vim.fn.json_decode(response.body).choices[1].message.content
	vim.cmd("vnew")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
	vim.api.nvim_set_option_value("filetype", "markdown", {})
	vim.api.nvim_set_option_value("buftype", "nofile", {})
end

function M.setup()
	vim.api.nvim_create_user_command("Ask", M.ask, { nargs = "*" })
end

return M
