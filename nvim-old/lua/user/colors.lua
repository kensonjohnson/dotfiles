----------------------------------------------------------------------
---- Theme Configurations --------------------------------------------
----------------------------------------------------------------------

--- Use Truecolor 24-bit colors in terminal
vim.opt.termguicolors = true

--- Moonfly
-- vim.cmd.colorscheme('moonfly')

--- Gruvbox
-- vim.opt.background = 'dark'
-- vim.g.gruvbox_contrast_dark = 'hard'
-- vim.g.termcolors = 256
-- vim.cmd.colorscheme('gruvbox')

--- kanagawa
require("kanagawa").setup({
  background = {
    dark = "dragon",
    light = "wave"
  }
})
vim.opt.background = 'dark'
vim.cmd.colorscheme("kanagawa")

require('mini.icons').setup()
