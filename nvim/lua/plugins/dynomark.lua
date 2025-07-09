return {
	"k-lar/dynomark.nvim",
	dependencies = "nvim-treesitter/nvim-treesitter",
	opts = {
		results_view_location = "horizontal",
	},
	keys = {
		{
			"<leader>v",
			"<cmd>Dynomark toggle<cr>",
			desc = "Dynomark Toggle",
		},
		{
			"<leader>V",
			"<cmd>Dynomark run<cr>",
			desc = "Dynomark Run Query",
		},
	},
}
