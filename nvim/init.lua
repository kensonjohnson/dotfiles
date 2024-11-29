----------------------------------------------------------------------
---- Globals ---------------------------------------------------------
----------------------------------------------------------------------
--- Set globals before plugins run

--- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--- If you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

----------------------------------------------------------------------
---- User Configs ----------------------------------------------------
----------------------------------------------------------------------

require("options")
require("keymaps")
