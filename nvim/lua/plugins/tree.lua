return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-tree").setup({
			actions = {
				open_file = {
					quit_on_open = true,
				},
			},
			vim.keymap.set("n", "\\", ":NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }),
			vim.keymap.set("n", "<leader>pe", ":NvimTreeToggle<CR>", { desc = "Open [P]roject [E]xplorer" }),
		})
	end,
}
