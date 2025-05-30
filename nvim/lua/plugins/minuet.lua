return {
	"milanglacier/minuet-ai.nvim",
	config = function()
		require("minuet").setup({
			blink = {
				enable_auto_complete = false,
			},
			lsp = {
				disabled_auto_trigger_ft = { "*" },
			},
			provider = "openai_fim_compatible",
			n_completions = 3, -- recommend for local model for resource saving
			provider_options = {
				openai_fim_compatible = {
					api_key = "TERM",
					name = "Ollama",
					end_point = "http://localhost:11434/v1/completions",
					model = "qwen2.5-coder:7b",
					optional = {
						max_tokens = 56,
						top_p = 0.9,
					},
				},
			},
		})
		vim.keymap.set("n", "<M-s>", "<Cmd>Minuet blink toggle<CR>")
		local virtualtext = require("minuet.virtualtext")
		vim.keymap.set("i", "<M-A>", virtualtext.action.accept)
		vim.keymap.set("i", "<M-a>", virtualtext.action.accept_line)
		vim.keymap.set("i", "<M-z>", virtualtext.action.accept_n_lines)
		vim.keymap.set("i", "<M-[>", virtualtext.action.prev)
		vim.keymap.set("i", "<M-]>", virtualtext.action.next)
		vim.keymap.set("i", "<M-e>", virtualtext.action.dismiss)
	end,
}
