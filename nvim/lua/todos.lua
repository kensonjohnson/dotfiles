-- Configuration
local LABEL_DONE = "Done:"
local TIMESTAMP_FORMAT = "%y%m%d-%H%M"

-- Shared helper functions
local function findTaskChunk()
	local api = vim.api
	local buf = api.nvim_get_current_buf()
	local cursor_pos = api.nvim_win_get_cursor(0)
	local start_line = cursor_pos[1] - 1
	local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
	local total_lines = #lines

	if start_line >= total_lines then
		return nil
	end

	-- Move upwards to find the bullet line
	while start_line > 0 do
		local line_text = lines[start_line + 1]
		if line_text == "" or line_text:match("^%s*%-") then
			break
		end
		start_line = start_line - 1
	end

	if lines[start_line + 1] == "" and start_line < (total_lines - 1) then
		start_line = start_line + 1
	end

	-- Validate task bullet
	local bullet_line = lines[start_line + 1]
	if not bullet_line:match("^%s*%- %[[x /%-%?!]%]") then
		return nil
	end

	-- Find chunk boundaries
	local chunk_start = start_line
	local chunk_end = start_line
	while chunk_end + 1 < total_lines do
		local next_line = lines[chunk_end + 2]
		if next_line == "" or next_line:match("^%s*%-") then
			break
		end
		chunk_end = chunk_end + 1
	end

	-- Collect chunk lines
	local chunk = {}
	for i = chunk_start, chunk_end do
		table.insert(chunk, lines[i + 1])
	end

	return {
		buf = buf,
		lines = lines,
		chunk = chunk,
		chunk_start = chunk_start,
		chunk_end = chunk_end
	}
end

local function setStatusChar(line, char)
	return line:gsub("^(%s*%- )%[[x /%-%?!]%]", "%1[" .. char .. "]")
end

local function removeLabel(line)
	return line:gsub("^(%s*%- %[[x /%-%?!]%])%s+`.-`", "%1")
end

local function insertLabelAfterBracket(line, label)
	local prefix = line:match("^(%s*%- %[[x /%-%?!]%])")
	if not prefix then
		return line
	end
	local rest = line:sub(#prefix + 1)
	return prefix .. " " .. label .. rest
end

local function getCurrentStatus(line)
	local status = line:match("^%s*%- %[([x /%-%?!])%]")
	return status or " "
end

local function hasLabel(line, label_pattern)
	return line:match("`" .. label_pattern .. ".-`") ~= nil
end

local function updateBuffer(task_data, new_chunk)
	for idx = task_data.chunk_start, task_data.chunk_end do
		task_data.lines[idx + 1] = new_chunk[idx - task_data.chunk_start + 1]
	end
	vim.api.nvim_buf_set_lines(task_data.buf, 0, -1, false, task_data.lines)
end

local function processTask(status_char, add_timestamp, status_name)
	vim.cmd("mkview")
	
	local task_data = findTaskChunk()
	if not task_data then
		print("Not a task bullet: no action taken.")
		vim.cmd("loadview")
		return
	end

	local chunk = task_data.chunk
	
	-- Set status and remove labels
	chunk[1] = setStatusChar(chunk[1], status_char)
	for i = 1, #chunk do
		chunk[i] = removeLabel(chunk[i])
	end

	-- Add timestamp if completing
	if add_timestamp then
		local timestamp = os.date(TIMESTAMP_FORMAT)
		chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. LABEL_DONE .. " " .. timestamp .. "`")
	end

	updateBuffer(task_data, chunk)
	vim.notify(status_name, vim.log.levels.INFO)
	vim.cmd("silent update")
	vim.cmd("loadview")
end

-- Main completion toggle
vim.keymap.set("n", "<M-x>", function()
	vim.cmd("mkview")
	
	local task_data = findTaskChunk()
	if not task_data then
		print("Not a task bullet: no action taken.")
		vim.cmd("loadview")
		return
	end

	local chunk = task_data.chunk
	
	-- Transform [Done: ...] labels to backticks
	for i, line in ipairs(chunk) do
		chunk[i] = line:gsub("%[" .. LABEL_DONE .. "([^%]]+)%]", "`" .. LABEL_DONE .. "%1`")
	end

	-- Check if chunk has done label
	local has_done_index = nil
	for i, line in ipairs(chunk) do
		if line:match("`" .. LABEL_DONE .. ".-`") then
			has_done_index = i
			break
		end
	end

	if has_done_index then
		-- Remove done label and set to blank
		chunk[has_done_index] = removeLabel(chunk[has_done_index]):gsub("`" .. LABEL_DONE .. ".-`", "")
		chunk[1] = setStatusChar(chunk[1], " ")
		chunk[1] = removeLabel(chunk[1])
		updateBuffer(task_data, chunk)
		vim.notify("Untoggled", vim.log.levels.INFO)
	else
		-- Mark as completed with timestamp
		local timestamp = os.date(TIMESTAMP_FORMAT)
		chunk[1] = setStatusChar(chunk[1], "x")
		chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. LABEL_DONE .. " " .. timestamp .. "`")
		updateBuffer(task_data, chunk)
		vim.notify("Completed", vim.log.levels.INFO)
	end

	vim.cmd("silent update")
	vim.cmd("loadview")
end, { desc = "[P]Toggle task completion status" })

-- Status setter keymaps
vim.keymap.set("n", "<M-/>", function()
	processTask("/", false, "Set to in progress")
end, { desc = "[P]Set task to in progress" })

vim.keymap.set("n", "<M-->", function()
	processTask("-", false, "Set to cancelled")
end, { desc = "[P]Set task to cancelled" })

vim.keymap.set("n", "<M-q>", function()
	processTask("?", false, "Set to question")
end, { desc = "[P]Set task to question" })

vim.keymap.set("n", "<M-i>", function()
	processTask("!", false, "Set to important")
end, { desc = "[P]Set task to important" })

-- Smart toggle
vim.keymap.set("n", "<M-t>", function()
	vim.cmd("mkview")
	
	local task_data = findTaskChunk()
	if not task_data then
		print("Not a task bullet: no action taken.")
		vim.cmd("loadview")
		return
	end

	local chunk = task_data.chunk
	local current_status = getCurrentStatus(chunk[1])
	
	-- Cycle logic: [ ] → [/] → [x] → [ ]
	-- Special cases: [-], [?], [!] → [x] → [ ]
	local cycle = {
		[" "] = { status = "/", name = "Set to in progress", timestamp = false },
		["/"] = { status = "x", name = "Completed", timestamp = true },
		["x"] = { status = " ", name = "Set to todo", timestamp = false },
		["-"] = { status = "x", name = "Completed", timestamp = true },
		["?"] = { status = "x", name = "Completed", timestamp = true },
		["!"] = { status = "x", name = "Completed", timestamp = true }
	}

	local next_state = cycle[current_status] or cycle[" "]
	
	-- Set status and remove labels
	chunk[1] = setStatusChar(chunk[1], next_state.status)
	for i = 1, #chunk do
		chunk[i] = removeLabel(chunk[i])
	end

	-- Add timestamp if completing
	if next_state.timestamp then
		local timestamp = os.date(TIMESTAMP_FORMAT)
		chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. LABEL_DONE .. " " .. timestamp .. "`")
	end

	updateBuffer(task_data, chunk)
	vim.notify(next_state.name, vim.log.levels.INFO)
	vim.cmd("silent update")
	vim.cmd("loadview")
end, { desc = "[P]Smart toggle task status" })

-- Telescope search keymaps
vim.keymap.set("n", "<leader>tt", function()
	require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
		prompt_title = "Incomplete Tasks",
		search = "^\\s*- \\[ \\]",
		search_dirs = { vim.fn.getcwd() },
		use_regex = true,
		initial_mode = "normal",
		layout_config = { preview_width = 0.5 },
		additional_args = function() return { "--no-ignore" } end,
	}))
end, { desc = "[P]Search for incomplete tasks" })

vim.keymap.set("n", "<leader>tc", function()
	require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
		prompt_title = "Completed Tasks",
		search = "^\\s*- \\[x\\] `" .. LABEL_DONE,
		search_dirs = { vim.fn.getcwd() },
		use_regex = true,
		initial_mode = "normal",
		layout_config = { preview_width = 0.5 },
		additional_args = function() return { "--no-ignore" } end,
	}))
end, { desc = "[P]Search for completed tasks" })