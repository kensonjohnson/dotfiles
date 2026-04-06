return {
	{ -- Highlight, edit, and navigate code
		-- nvim-treesitter has been archived and is incompatible with Neovim 0.12.0+
		-- Use built-in treesitter with ts-comments.nvim instead
		-- Reference: https://github.com/nvim-treesitter/nvim-treesitter/issues/7846
		"folke/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
	},
}
