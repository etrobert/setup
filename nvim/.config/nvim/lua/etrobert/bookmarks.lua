local M = {}

local config = {
	max_description = 140,
	max_html_bytes = 200 * 1024,
}

local namespace = vim.api.nvim_create_namespace("etrobert_bookmarks")

local state = {
	cache = {},
	pending = {},
	buffers = {},
	notified = {},
}

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

local function sanitize(text)
	if not text or text == "" then
		return nil
	end
	return text
end

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

local function build_lines(link, metadata, status)
	local prefix = "* "
	local indent = "  "

	if status == "loading" then
		return {
			{ { prefix, "Comment" }, { "Loading bookmark...", "Comment" } },
			{ { indent, "Comment" }, { "", "Comment" } },
		}
	end

	if status == "error" then
		return {
			{ { prefix, "Comment" }, { "Unable to load preview", "WarningMsg" } },
			{ { indent, "Comment" }, { "", "Directory" } },
		}
	end

	local title = metadata.title or link.text or link.url
	local description = metadata.description or ""

	if config.max_description and config.max_description > 0 then
		description = truncate(description, config.max_description)
	end

	return {
		{ { prefix, "Comment" }, { title or "", "Title" } },
		{ { indent, "Comment" }, { description, "Comment" } },
	}
end

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
			if not metadata and not state.notified[url] then
				state.notified[url] = true
				vim.schedule(function()
					vim.notify(string.format("bookmarks: failed to load metadata for %s", url), vim.log.levels.WARN)
				end)
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
		if not state.notified[url] then
			state.notified[url] = true
			vim.schedule(function()
				vim.notify(string.format("bookmarks: unable to start fetch for %s", url), vim.log.levels.WARN)
			end)
		end
	end
end

local function render_entry(bufnr, entry, metadata, status)
	local lines = build_lines(entry.link, metadata or {}, status)

	entry.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, namespace, entry.link.end_row, 0, {
		id = entry.extmark_id,
		virt_lines = lines,
		hl_mode = "combine",
	})
end

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

local function buffer_matches(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local matches = {}
	for i, line in ipairs(lines) do
		local col = 1
		while true do
			local start_link, end_link, text, url = line:find("%[(.-)%]%((.-)%)", col)
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
				table.insert(matches, {
					start_row = i - 1,
					start_col = start_auto - 1,
					end_row = i - 1,
					end_col = end_auto,
					text = auto_url,
					url = auto_url,
				})
				col = end_auto + 1
			end
		end
	end
	return matches
end

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
