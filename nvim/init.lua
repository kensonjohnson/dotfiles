----------------------------------------------------------------------
---- User Configs ----------------------------------------------------
----------------------------------------------------------------------

--- Remaps must come before plugins or the wrong leader key is used.
require("user.remap")
require("user.options")

----------------------------------------------------------------------
---- Bootstrap & Run Plugin Manager ----------------------------------
----------------------------------------------------------------------

--- Bootstrap lazy.nvim plugin manager.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--- Setup plugins
require("lazy").setup({
  --- This spot is good for plugins that don't require configuration.

  --- Detect tabstop and shiftwidth automagically.
  'tpope/vim-sleuth',

  --- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim',  opts = {} },

  --- Automagically create closing brackets
  { 'm4xshen/autoclose.nvim', opts = {} },

  --- Compile all of the configurations in the plugins directory.
  { import = "plugins" }
}, {})

----------------------------------------------------------------------
---- Configure Plugins -----------------------------------------------
----------------------------------------------------------------------

require("user.colors")
require("user.telescope")
require("user.treesitter")
require("user.lsp")
require("user.nvim-cmp")
require("user.harpoon")
require("user.git")
require("user.snippets")
