return {
	--- Detect tabstop and shiftwidth automagically
	{
		"tpope/vim-sleuth",
		event = "VeryLazy",
	},

	--- <leader>gc to comment visually selected regions
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		opts = {},
	},

	--- Create closing brackets automagically
	{
		"m4xshen/autoclose.nvim",
		event = "VeryLazy",
		opts = {},
	},

	--- Allow the use of <ESC> to leave built-in terminal
	{
		"sychen52/smart-term-esc.nvim",
		event = "VeryLazy",
		config = function()
			require("smart-term-esc").setup({
				key = "<Esc>",
				except = { "nvim", "fzf" },
			})
		end,
	},

	--- Keep the cursor from reaching the bottom of the buffer
	{
		"Aasim-A/scrollEOF.nvim",
		event = { "CursorMoved", "WinScrolled" },
		opts = {},
	},

	--- Add indentation guides even on blank lines
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "VeryLazy",
		main = "ibl",
		opts = {},
	},

	--- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = { signs = false },
	},

	--- Fix tailwindcss class ordering for templ files
	{
		"laytan/tailwind-sorter.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
		build = "cd formatter && npm ci && npm run build",
		config = {
			on_save_enabled = true,
			on_save_pattern = { "*.templ" }, -- The file patterns to watch and sort.
			node_path = "node",
			trim_spaces = true,
		},
	},
}
