return {
	{
		--- Awesome git interface
		"NeogitOrg/neogit",
		lazy = true,
		cmd = "Neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
			config = true,
		},
		config = function()
			require("neogit").setup({
				commit_editor = {
					kind = "tab",
					show_staged_diff = true,
					staged_diff_split_kind = "split",
					spell_check = true,
				},
			})

			--- Setup commit message generator with custom config
			require("commit-generator").setup({
				ai = {
					enabled = true,
					provider = "openai-codex",
					model = "gpt-5.6-luna",
					thinking = "low",
					timeout = 30000,
				},
				format = {
					conventional_commits = true,
					max_length = 50,
					include_scope = true,
				},
			})
		end,
	},
	{
		--- Adds git related signs to the gutter
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
}
