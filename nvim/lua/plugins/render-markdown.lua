return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		dash = { width = 80 },
		code = {
			disable_background = { "diff", "dynomark" },
			language_border = " ",
			language_left = "█",
			language_right = "",
			width = "block",
			min_width = 80,
		},
		checkbox = {
			unchecked = { icon = " " },
			checked = { icon = "  " },
			custom = {
				todo = { raw = "" }, -- delete the preset 'todo'
				progress = {
					raw = "[/]",
					rendered = " ",
					highlight = "RenderMarkdownUnchecked",
				},
				will_not_do = {
					raw = "[-]",
					rendered = " ",
					highlight = "RenderMarkdownWarn",
				},
				important = {
					raw = "[!]",
					rendered = " ",
					highlight = "RenderMarkdownError",
					scope_highlight = "RenderMarkdownError",
				},
				question = {
					raw = "[?]",
					rendered = " ",
					highlight = "RenderMarkdownWarn",
					scope_highlight = "RenderMarkdownWarn",
				},
			},
		},
	},
}
