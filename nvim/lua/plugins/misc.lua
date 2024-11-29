return {
  --- Detect tabstop and shiftwidth automagically
  'tpope/vim-sleuth',

  --- <leader>gc to comment visually selected regions
  { 'numToStr/Comment.nvim',  opts = {} },

  --- Create closing brackets automagically
  { 'm4xshen/autoclose.nvim', opts = {} },

  --- Allow the use of <ESC> to leave built-in terminal
  {
    "sychen52/smart-term-esc.nvim",
    config = function()
      require("smart-term-esc").setup {
        key = "<Esc>",
        except = { "nvim", "fzf" }
      }
    end
  },

  --- Keep the cursor from reaching the bottom of the buffer
  {
    'Aasim-A/scrollEOF.nvim',
    event = { 'CursorMoved', 'WinScrolled' },
    opts = {},
  },

  --- Add indentation guides even on blank lines
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },
}
