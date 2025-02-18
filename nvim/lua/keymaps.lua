----------------------------------------------------------------------
---- Custom Remaps ---------------------------------------------------
----------------------------------------------------------------------

--- Write buffer to file
vim.keymap.set("n", "<leader>w", ":w<CR>")

--- Escape INSERT mode
vim.keymap.set("i", "jj", "<esc>")
vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("i", "kk", "<esc>")

--- Append line while keeping cursor at column 0
vim.keymap.set("n", "J", "mzJ`z")

--- Keep cursor centered when jumping by page
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

--- Keep cursor centered when jumping by search term
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

--- Quickfix list navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

--- Clear search highlighting
vim.keymap.set("n", "<Esc>", vim.cmd.nohls)

--- Paste without replacing buffer in VISUAL mode
vim.keymap.set("x", "<leader>p", [["_dP]])

--- Delete character without replacing buffer
vim.keymap.set({ "n", "x" }, "x", [["_x]])

--- Yank to system keyboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])

--- Yank contents of entire file to system clipboard
vim.keymap.set("n", "<leader>Y", [[gg"+yG]])

--- Globally rename word cursor is on
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

--- Make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

--- Move VISUAL highlighted region up or down
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--- Helps with accidentally trying a keymap in the wrong mode
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

--- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

--- Helpful window navigation commands
vim.keymap.set("n", "<Left>", "<C-w>h", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<Right>", "<C-w>l", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<Down>", "<C-w>j", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<Up>", "<C-w>k", { desc = "Move focus to the upper window" })
vim.keymap.set("n", "<C-Left>", "<C-w><", { desc = "Decrease the width of the current window" })
vim.keymap.set("n", "<C-Right>", "<C-w>>", { desc = "Increase the width of the current window" })
vim.keymap.set("n", "<C-Down>", "<C-w>-", { desc = "Decrease the height of the current window" })
vim.keymap.set("n", "<C-Up>", "<C-w>+", { desc = "Increase the height of the current window" })

--- Create interactive terminals
vim.keymap.set("n", "<leader>t", "<cmd>terminal<CR>", { desc = "Open [t]erminal in current window" })
vim.keymap.set("n", "<leader>ts", "<cmd>split | terminal<CR>", { desc = "Open [t]erminal in a [s]plit window" })
vim.keymap.set(
	"n",
	"<leader>tv",
	"<cmd>vsplit | terminal<CR>",
	{ desc = "Open [t]erminal in a [v]ertical split window" }
)

--- :!just keymaps
vim.keymap.set("n", "<leader>jr", "<cmd>split | terminal just run<CR>", { desc = "[j]ust [r]un" })
vim.keymap.set("n", "<leader>jd", "<cmd>split | terminal just dev<CR>", { desc = "[j]ust [d]ev" })

-- Twilight
vim.keymap.set("n", "<leader>tw", ":Twilight<enter>", { desc = "Toggle [TW]ilight" })

-- ZenMode
vim.keymap.set("n", "<leader>zm", ":ZenMode<enter>", { desc = "Toggle [Z]en[Mode]" })
