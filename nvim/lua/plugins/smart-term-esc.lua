return {
  {
    "sychen52/smart-term-esc.nvim",
    config = function()
      require("smart-term-esc").setup {
        key = "<Esc>",
        except = { "nvim", "fzf" }
      }
    end
  }
}
