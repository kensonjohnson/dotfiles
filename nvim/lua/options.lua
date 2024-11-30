----------------------------------------------------------------------
---- Editor Configurations -------------------------------------------
----------------------------------------------------------------------

--- Use Truecolor 24-bit colors in terminal
vim.opt.termguicolors = true

--- Turn on syntax for any theme
vim.opt.syntax = "on"

--- Add relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

--- Sets distance from bottom of screen before auto-scrolling
vim.opt.scrolloff = 10

--- Ignores uppercase when searching unless uppercase is in search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

--- Allow line wrap to virtual lines
vim.opt.wrap = true

--- Preserve indentation on virtual lines
vim.opt.breakindent = true

--- Set tabstop and indentation preferences
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

--- Use persistent undo
vim.opt.undofile = true

--- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

--- Better completion experience
vim.opt.completeopt = "menuone,noselect"

--- signcolumn by default
vim.opt.signcolumn = "yes"

--- Add column at 80 characters
vim.opt.colorcolumn = "80"

--- Open splits on the bottom
vim.opt.splitbelow = true
vim.opt.splitright = true

--- Enable mouse mode, useful for re-sizing splits
vim.opt.mouse = "a"

--- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

--- Enable spellchecker
vim.opt.spelllang = "en_us"
vim.opt.spell = true

--- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})
