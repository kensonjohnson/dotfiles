return {
	{
		"notes.nvim",
		dir = "~/Developer/repos/notes.nvim",
		name = "notes",
		dev = true,
		config = function()
			require("notes").setup({
				pkm_dir = "~/Developer/pkm",
			})
		end,
		keys = {
			{
				"<leader>nd",
				function()
					require("notes").daily_note()
				end,
				desc = "Open daily note",
			},
			{
				"<leader>nt",
				function()
					require("notes").tomorrow_note()
				end,
				desc = "Open tomorrow note",
			},
			{
				"<leader>nn",
				function()
					require("notes").quick_note()
				end,
				desc = "Create quick note",
			},
		},
		cmd = { "DailyNote", "TomorrowNote", "QuickNote" },
	},
}
