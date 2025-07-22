-- PKM directory configuration
local PKM_DIR = vim.env.HOME .. "/Developer/pkm"

-- Create directory if it doesn't exist
local function ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

-- Generate random alphanumeric string for note names
local function generate_random_id(length)
	local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
	local result = ""
	for _ = 1, length do
		local rand_index = math.random(1, #chars)
		result = result .. chars:sub(rand_index, rand_index)
	end
	return result
end

-- Create daily note with date-based structure
local function daily_note()
	local main_note_dir = PKM_DIR .. "/Daily"

	-- Get current date components
	local current_year = os.date("%Y")
	local current_month_num = os.date("%m")
	local current_month_abbr = os.date("%b")
	local current_day = os.date("%d")
	local current_weekday = os.date("%A") --[[@as string]]

	-- Construct directory structure and filename
	local note_dir = main_note_dir .. "/" .. current_year .. "/" .. current_month_num .. "-" .. current_month_abbr
	local note_name = current_year .. "-" .. current_month_num .. "-" .. current_day .. "-" .. current_weekday
	local full_path = note_dir .. "/" .. note_name .. ".md"

	-- Create directory if it doesn't exist
	ensure_dir(note_dir)

	-- Create the daily note if it doesn't already exist
	if vim.fn.filereadable(full_path) == 0 then
		local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
		local note_id = current_year
			.. "-"
			.. current_month_num
			.. "-"
			.. current_day
			.. "-"
			.. string.lower(current_weekday)
		local human_date = os.date("%A, %B %d, %Y")
		local template = {
			"---",
			"id: " .. note_id,
			"created: " .. timestamp,
			"modified: " .. timestamp,
			"tags: [daily]",
			"---",
			"",
			"# " .. human_date,
			"",
			"## Tasks",
			"",
			"## Notes",
			"",
		}
		vim.fn.writefile(template, full_path)
	end

	-- Change to PKM directory and open the file
	vim.cmd("cd " .. PKM_DIR)
	vim.cmd("edit " .. full_path)
end

-- Create quick note in inbox with random name
local function quick_note()
	local inbox_dir = PKM_DIR .. "/+Inbox"

	-- Generate random filename (8 characters)
	local random_name = generate_random_id(8)
	local full_path = inbox_dir .. "/" .. random_name .. ".md"

	-- Create inbox directory if it doesn't exist
	ensure_dir(inbox_dir)

	-- Create the note file with template
	local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
	local template = {
		"---",
		"id: " .. random_name,
		"created: " .. timestamp,
		"modified: " .. timestamp,
		"tags: []",
		"---",
		"",
		"# " .. random_name,
		"",
	}
	vim.fn.writefile(template, full_path)

	-- Change to PKM directory and open the file
	vim.cmd("cd " .. PKM_DIR)
	vim.cmd("edit " .. full_path)
end

-- Update modified timestamp in frontmatter on save
local function update_modified_timestamp()
	local filepath = vim.fn.expand("%:p")

	-- Short circuit: only process files in PKM directory
	if not filepath:find(PKM_DIR, 1, true) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local in_frontmatter = false
	local frontmatter_end = nil

	-- Find frontmatter boundaries
	for i, line in ipairs(lines) do
		if line == "---" then
			if not in_frontmatter then
				in_frontmatter = true
			else
				frontmatter_end = i
				break
			end
		end
	end

	-- If no frontmatter found, return
	if not frontmatter_end then
		return
	end

	-- Update modified field
	local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
	for i = 2, frontmatter_end - 1 do
		if lines[i]:match("^modified:") then
			lines[i] = "modified: " .. timestamp
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
			return
		end
	end
end

-- Autocommand to update modified timestamp on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.md",
	callback = update_modified_timestamp,
	desc = "Update modified timestamp in PKM notes",
})

-- Keymaps
vim.keymap.set("n", "<leader>nd", daily_note, { desc = "Create/open [d]aily [n]ote" })
vim.keymap.set("n", "<leader>nn", quick_note, { desc = "Create [n]ew [n]ote" })

return {
	daily_note = daily_note,
	quick_note = quick_note,
}
