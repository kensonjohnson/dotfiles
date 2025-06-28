return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = false,
				theme = "moonfly",
				component_separators = "|",
				section_separators = "",
			},
			sections = {
				lualine_x = {
					"filetype",
				},
			},
		})
	end,
}
