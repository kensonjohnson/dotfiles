return {
   "rebelot/kanagawa.nvim",
    lazy = true,
    config = function()
      require("kanagawa").setup{}
      vim.cmd.colorscheme("kanagawa-dragon")
    end,
}
