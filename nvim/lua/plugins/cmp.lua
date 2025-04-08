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
					["<A-y>"] = require("minuet").make_blink_map(),
				},
				appearance = {
					nerd_font_variant = "mono",
				},
				completion = {
					documentation = { auto_show = false },
					ghost_text = { enabled = true },
					trigger = { prefetch_on_insert = false },
				},
				sources = {
					default = { "lsp", "path", "snippets", "buffer", "minuet" },
					providers = {
						minuet = {
							name = "minuet",
							module = "minuet.blink",
							score_offset = 8, -- gives minuet higher priority
						},
					},
				},
				fuzzy = { implementation = "prefer_rust_with_warning" },
				signature = { enabled = true },
			})
		end,
		opts_extend = { "sources.default" },
	},
}
