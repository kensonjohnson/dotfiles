return {
	"kensonjohnson/dynomark.nvim",
	branch = "main",
	dependencies = "nvim-treesitter/nvim-treesitter",
	ft = "markdown",
	config = function()
		require("dynomark").setup({
			results_view_location = "horizontal",
		})

		-- Track if Dynomark has been globally enabled
		local dynomark_enabled = false

		-- Auto-enable for first markdown file opened
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function()
				if not dynomark_enabled then
					dynomark_enabled = true
					vim.schedule(function()
						vim.cmd("Dynomark toggle")
					end)
				end
			end,
		})
	end,
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
