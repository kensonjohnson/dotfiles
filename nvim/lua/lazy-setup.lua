local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  --- This is a good place for plugins that don't require configuration.

  --- Detect tabstop and shiftwidth automagically
  'tpope/vim-sleuth',

  --- <leader>gc to comment visually selected regions
  'numToStr/Comment.nvim',

  --- Create closing brackets automagically
  'm4xshen/autoclose.nvim', 

  --- Load all plugins defined in 'lua/plugins'
  { import = "plugins" },
},{})
