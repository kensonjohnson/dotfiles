----------------------------------------------------------------------
---- Globals ---------------------------------------------------------
----------------------------------------------------------------------
--- Set globals before plugins run

--- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--- If you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

--- Disable netrw, since we're using nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

----------------------------------------------------------------------
---- User Configs ----------------------------------------------------
----------------------------------------------------------------------

require("options")
require("autocommands")
require("keymaps")
require("todos")
require("notes")
require("filetypes")

----------------------------------------------------------------------
---- Bootstrap & Run Plugin Manager ----------------------------------
----------------------------------------------------------------------

require("lazy-setup")
