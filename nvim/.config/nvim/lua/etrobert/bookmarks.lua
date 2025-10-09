local M = {}

---@class Metadata
---@field title string
---@field description string
---@field image string

local config = {
	max_description = 140,
	max_html_bytes = 200 * 1024,
}

local namespace = vim.api.nvim_create_namespace("etrobert_bookmarks")

---@class Entry
---@field link Match
---@field metadata Metadata | nil
---@field extmark_id integer | nil

---@class BufferState
---@field links table<string, Entry>

---@class State
---@field cache table<string, Metadata | false>
---@field pending table<string, function[]>
---@field buffers table<integer, BufferState>

---@type State
local state = {
	cache = {},
	pending = {},
	buffers = {},
}

---@nodiscard
---@param text string
---@param max_len integer
---@return string
local function truncate(text, max_len)
	if not text or text == "" then
		return text
	end
	if max_len <= 0 or #text <= max_len then
		return text
	end
	if max_len <= 3 then
		return text:sub(1, max_len)
	end
	return text:sub(1, max_len - 3) .. "..."
end

---@nodiscard
---@param text string
---@return string | nil
local function sanitize(text)
	if not text or text == "" then
		return nil
	end
	return text
end

---@nodiscard
---@param fragment string
---@return { [string]: string }
local function parse_meta_fragment(fragment)
	local attrs = {}
	for key, value in fragment:gmatch('([%w:-]+)%s*=%s*"(.-)"') do
		attrs[key:lower()] = value
	end
	for key, value in fragment:gmatch("([%w:-]+)%s*=%s*'(.-)'") do
		attrs[key:lower()] = value
	end
	return attrs
end

---@param html string | nil
---@return Metadata | nil
local function extract_metadata(html)
	if not html or html == "" then
		return nil
	end

	local meta = {}
	for fragment in html:gmatch("<meta%s+.-%s*/?>") do
		local attrs = parse_meta_fragment(fragment)
		local name = (attrs.name or attrs.property or ""):lower()
		if (name == "og:title" or name == "twitter:title") and not meta.title then
			meta.title = attrs.content
		elseif
			(name == "og:description" or name == "twitter:description" or name == "description")
			and not meta.description
		then
			meta.description = attrs.content
		elseif (name == "og:image" or name == "twitter:image") and not meta.image then
			meta.image = attrs.content
		end
		if meta.title and meta.description and meta.image then
			break
		end
	end

	if not meta.title then
		local title = html:match("<[Tt][Ii][Tt][Ll][Ee][^>]*>(.-)</[Tt][Ii][Tt][Ll][Ee]>")
		if title then
			meta.title = title
		end
	end

	meta.title = sanitize(meta.title)
	meta.description = sanitize(meta.description)
	meta.image = sanitize(meta.image)

	if not meta.title and not meta.description and not meta.image then
		return nil
	end

	return meta
end

---@alias Status "loading" | "error"

---@alias Line [string, string][] -- [text, highlight][]

---@param link Match
---@param metadata Metadata
---@param status Status | nil
---@param table_info TableInfo | nil
---@return [Line, Line]
local function build_lines(link, metadata, status, table_info)
	-- Calculate spacing for table alignment
	local prefix = ""
	local max_width = config.max_description

	if table_info and table_info.is_table then
		-- Add spaces to align with column start plus one extra space
		prefix = string.rep(" ", table_info.col_start + 1)
		-- Calculate available width in column
		local col_width = table_info.col_end - table_info.col_start
		max_width = math.min(col_width - 3, config.max_description or 140) -- -3 for padding + extra space
	else
		prefix = "* "
	end

	if status == "loading" then
		return {
			{ { prefix, "Comment" }, { "Loading bookmark...", "Comment" } },
			{ { prefix, "Comment" }, { "", "Comment" } },
		}
	end

	if status == "error" then
		return {
			{ { prefix, "Comment" }, { "Unable to load preview", "WarningMsg" } },
			{ { prefix, "Comment" }, { "", "Directory" } },
		}
	end

	local title = metadata.title or link.text or link.url
	local description = metadata.description or ""

	-- Truncate based on available width
	if max_width and max_width > 0 then
		if title then
			title = truncate(title, max_width)
		end
		if description then
			description = truncate(description, max_width)
		end
	end

	return {
		{ { prefix, "Comment" }, { title or "", "Title" } },
		{ { prefix, "Comment" }, { description, "Comment" } },
	}
end

---@class TableInfo
---@field is_table boolean
---@field col_start integer
---@field col_end integer

---@nodiscard
---@param bufnr integer
---@param row integer
---@param col integer
---@return TableInfo
local function get_table_info(bufnr, row, col)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local line = lines[row + 1]
	if not line then
		return { is_table = false, col_start = 0, col_end = 0 }
	end

	-- Check if current line contains table separators
	if not line:match("|") then
		return { is_table = false, col_start = 0, col_end = 0 }
	end

	-- Look for table header separator (line with |:--|:--|)
	local is_table = false
	for i = math.max(1, row - 2), math.min(#lines, row + 3) do
		local check_line = lines[i]
		if check_line and check_line:match("^%s*|?[%s:%-|]+|?%s*$") and check_line:match("%-") then
			is_table = true
			break
		end
	end

	if not is_table then
		return { is_table = false, col_start = 0, col_end = 0 }
	end

	-- Find column boundaries
	local col_start = 0
	local col_end = #line
	local pipe_positions = {}

	-- Find all pipe positions
	for i = 1, #line do
		if line:sub(i, i) == "|" then
			table.insert(pipe_positions, i - 1) -- convert to 0-based
		end
	end

	-- Find which column the link is in
	for i = 1, #pipe_positions - 1 do
		if col >= pipe_positions[i] and col <= pipe_positions[i + 1] then
			col_start = pipe_positions[i] + 1 -- skip the pipe
			col_end = pipe_positions[i + 1] - 1 -- before next pipe
			break
		end
	end

	-- Handle edge cases
	if #pipe_positions > 0 and col < pipe_positions[1] then
		col_start = 0
		col_end = pipe_positions[1] - 1
	elseif #pipe_positions > 0 and col > pipe_positions[#pipe_positions] then
		col_start = pipe_positions[#pipe_positions] + 1
		col_end = #line
	end

	return { is_table = true, col_start = col_start, col_end = col_end }
end

---@param url string
---@param callback fun(metadata: Metadata | nil): nil
local function fetch_metadata(url, callback)
	local cached = state.cache[url]
	if cached ~= nil then
		callback(cached ~= false and cached or nil)
		return
	end

	if state.pending[url] then
		table.insert(state.pending[url], callback)
		return
	end

	state.pending[url] = { callback }

	local command = vim.deepcopy({ "curl", "-L", "-m", "5", "-s" })
	table.insert(command, url)
	local stdout = {}

	local job_id = vim.fn.jobstart(command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if not data then
				return
			end
			for _, chunk in ipairs(data) do
				if chunk ~= "" then
					table.insert(stdout, chunk)
				end
			end
		end,
		on_exit = function(_, code)
			local body = table.concat(stdout, "\n")
			if #body > config.max_html_bytes then
				body = body:sub(1, config.max_html_bytes)
			end
			local metadata = nil
			if code == 0 then
				metadata = extract_metadata(body)
			end
			state.cache[url] = metadata or false
			local callbacks = state.pending[url] or {}
			state.pending[url] = nil
			for _, cb in ipairs(callbacks) do
				cb(metadata)
			end
		end,
	})

	if job_id <= 0 then
		state.cache[url] = false
		local callbacks = state.pending[url] or {}
		state.pending[url] = nil
		for _, cb in ipairs(callbacks) do
			cb(nil)
		end
	end
end

---@param bufnr integer
---@param entry Entry
---@param metadata Metadata | nil
---@param status Status | nil
local function render_entry(bufnr, entry, metadata, status)
	local table_info = get_table_info(bufnr, entry.link.end_row, entry.link.start_col)
	local lines = build_lines(entry.link, metadata or {}, status, table_info)

	-- Always use virtual lines, but with column-aware spacing
	entry.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, namespace, entry.link.end_row, 0, {
		id = entry.extmark_id,
		virt_lines = lines,
		hl_mode = "combine",
	})
end

---@param bufnr integer
---@param key string
---@param entry Entry
local function refresh_link(bufnr, key, entry)
	local url = entry.link.url
	local cached = state.cache[url]
	if cached == nil then
		render_entry(bufnr, entry, nil, "loading")
		fetch_metadata(url, function(result)
			vim.schedule(function()
				if not vim.api.nvim_buf_is_loaded(bufnr) then
					return
				end
				local buffer_state = state.buffers[bufnr]
				if not buffer_state then
					return
				end
				local current = buffer_state.links[key]
				if not current then
					return
				end
				if result then
					current.metadata = result
					render_entry(bufnr, current, result)
				else
					render_entry(bufnr, current, nil, "error")
				end
			end)
		end)
	elseif cached == false then
		render_entry(bufnr, entry, nil, "error")
	else
		entry.metadata = cached
		render_entry(bufnr, entry, cached)
	end
end

---@class Match
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer
---@field text string
---@field url string

---@nodiscard
---@param bufnr integer
---@return Match[]
local function buffer_matches(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local matches = {}
	for i, line in ipairs(lines) do
		local col = 1
		while true do
			local start_link, end_link, text, url = line:find("%[(.-)%]%((.-)%)", col)

			-- Skip image links (starting with !)
			if start_link and start_link > 1 and line:sub(start_link - 1, start_link - 1) == "!" then
				start_link = nil
			end

			local start_auto, end_auto, auto_url = line:find("<([^%s>]+)>", col)

			if not start_link and not start_auto then
				break
			end

			if start_link and (not start_auto or start_link <= start_auto) then
				table.insert(matches, {
					start_row = i - 1,
					start_col = start_link - 1,
					end_row = i - 1,
					end_col = end_link,
					text = text,
					url = url,
				})
				col = end_link + 1
			else
				if auto_url:match("^https?://") or auto_url:match("^mailto:") then
					table.insert(matches, {
						start_row = i - 1,
						start_col = start_auto - 1,
						end_row = i - 1,
						end_col = end_auto,
						text = auto_url,
						url = auto_url,
					})
				end
				col = end_auto + 1
			end
		end
	end
	return matches
end

---@param bufnr integer
local function refresh_buffer(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
	local matches = buffer_matches(bufnr)
	local buffer_state = state.buffers[bufnr]
	local new_links = {}

	for _, match in ipairs(matches) do
		local key = string.format("%d:%d:%s", match.start_row, match.start_col, match.url)
		local entry = buffer_state.links[key] or {}
		entry.link = match
		new_links[key] = entry
		refresh_link(bufnr, key, entry)
	end

	buffer_state.links = new_links
end

---@param bufnr integer
local function attach_buffer(bufnr)
	if state.buffers[bufnr] then
		return
	end
	vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
		buffer = bufnr,
		callback = function()
			refresh_buffer(bufnr)
		end,
	})
	state.buffers[bufnr] = { links = {} }
	refresh_buffer(bufnr)
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function(args)
			attach_buffer(args.buf)
		end,
	})
end

return M
