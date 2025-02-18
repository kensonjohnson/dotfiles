return {
	"folke/twilight.nvim",
	{
		"preservim/vim-pencil",
		lazy = true,
		init = function()
			vim.g["pencil#wrapModeDefault"] = "soft"
		end,
	},
	{
		"folke/zen-mode.nvim",
		opts = {
			window = {
				backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
				width = 120, -- width of the Zen window
				height = 1, -- height of the Zen window
				options = {
					signcolumn = "no", -- disable signcolumn
					number = false, -- disable number column
					relativenumber = false, -- disable relative numbers
				},
			},
			plugins = {
				options = {
					enabled = true,
					ruler = false, -- disables the ruler text in the cmd line area
					showcmd = false, -- disables the command in the last line of the screen
					-- you may turn on/off statusline in zen mode by setting 'laststatus'
					-- statusline will be shown only if 'laststatus' == 3
					laststatus = 0, -- turn off the statusline in zen mode
				},
				twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
				gitsigns = { enabled = false }, -- disables git signs
				todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
			},
		},
	},
}
