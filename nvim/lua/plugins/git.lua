return {
	{
		--- Standalone direct-Codex commit message generator
		name = "commit-generator",
		dir = vim.fn.stdpath("config"),
		lazy = true,
		cmd = {
			"CommitGeneratorLogin",
			"CommitGeneratorStatus",
			"CommitGeneratorLogout",
			"GenerateCommitMsg",
		},
		ft = "gitcommit",
		config = function()
			require("commit-generator").setup({
				ai = {
					enabled = true,
					model = "gpt-5.6-luna",
					timeout = 30000,
					storage = {
						backend = "auto",
					},
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
