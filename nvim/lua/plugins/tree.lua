return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = true,
  requires = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      vim.api.nvim_set_keymap("n", "<leader>et", ":NvimTreeToggle<enter>", { desc = "[E]xplorer [t]oggle" }),
      vim.keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>",
        { desc = "Toggle file explorer on current file" }),
      vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }),
      vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })
    })
  end,
}
