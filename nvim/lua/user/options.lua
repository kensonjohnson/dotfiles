----------------------------------------------------------------------
---- Editor Configurations -------------------------------------------
----------------------------------------------------------------------

--- Set globals before plugins run
vim.g.have_nerd_font = true

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

--- Turn on syntax for any theme
vim.opt.syntax = 'on'

--- Set clang as default compiler
vim.opt.makeprg = 'clang++'

--- Use persistent undo
vim.opt.undofile = true

--- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 250

--- Better completion experience
vim.opt.completeopt = 'menuone,noselect'

--- signcolumn by default
vim.opt.signcolumn = 'yes'

--- Add column at 80 characters
vim.opt.colorcolumn = '80'

--- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})
