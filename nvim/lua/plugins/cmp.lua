return {
	{
		"saghen/blink.cmp",
		dependencies = { "rafamadriz/friendly-snippets" },
		version = "1.*",
		config = function()
			---@module 'blink.cmp'
			---@type blink.cmp.Config
			require("blink-cmp").setup({
				keymap = {
					preset = "enter",
				},
				appearance = {
					nerd_font_variant = "mono",
				},
				completion = {
					documentation = { auto_show = false },
				},
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
				},
				fuzzy = { implementation = "prefer_rust_with_warning" },
				signature = { enabled = true },
			})
		end,
		opts_extend = { "sources.default" },
	},
}
