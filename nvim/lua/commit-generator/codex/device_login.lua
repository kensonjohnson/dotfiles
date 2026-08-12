local M = {}

local function display_width(fn, text)
  if fn.strdisplaywidth then
    return fn.strdisplaywidth(text)
  end
  return #text
end

function M.show(opts)
  assert(type(opts) == "table", "device login options are required")
  assert(type(opts.url) == "string" and opts.url ~= "", "device verification URL is required")
  assert(type(opts.user_code) == "string" and opts.user_code ~= "", "device user code is required")
  assert(type(opts.open_url) == "function", "device URL opener is required")

  local api = opts.api or vim.api
  local fn = opts.fn or vim.fn
  local keymap = opts.keymap or vim.keymap
  local notify = opts.notify or vim.notify
  local levels = opts.levels or vim.log.levels
  local lines = {
    "OpenAI device authorization",
    "",
    "Verification URL: " .. opts.url,
    "Code: " .. opts.user_code,
    "",
    "[y] Copy code  [Enter] Open URL  [q/Esc] Close",
  }
  local widest = 0
  for _, line in ipairs(lines) do
    widest = math.max(widest, display_width(fn, line))
  end

  local ui = api.nvim_list_uis()[1]
  local columns = opts.columns or (ui and ui.width) or vim.o.columns
  local rows = opts.rows or (ui and ui.height) or vim.o.lines
  local width = math.min(widest + 4, math.max(1, columns - 4))
  local height = #lines
  local win = api.nvim_open_win(api.nvim_create_buf(false, true), true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((rows - height) / 2)),
    col = math.max(0, math.floor((columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " Device login ",
    title_pos = "center",
  })
  local buf = api.nvim_win_get_buf(win)
  api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  api.nvim_set_option_value("modifiable", true, { buf = buf })
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = buf })

  local function close()
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end

  keymap.set("n", "y", function()
    fn.setreg("+", opts.user_code)
    notify("Device authorization code copied to clipboard", levels.INFO)
  end, { buffer = buf, nowait = true, silent = true, desc = "Copy device authorization code" })
  keymap.set("n", "<CR>", function()
    local opened, err = opts.open_url()
    if not opened then
      notify(err or "could not open the device authorization page", levels.WARN)
    end
  end, { buffer = buf, nowait = true, silent = true, desc = "Open device authorization page" })
  keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true, desc = "Close device authorization" })
  keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true, desc = "Close device authorization" })

  return { win = win, close = close }
end

return M
