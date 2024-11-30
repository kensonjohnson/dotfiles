----------------------------------------------------------------------
---- Custom Remaps ---------------------------------------------------
----------------------------------------------------------------------

--- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--- Write buffer to file
vim.keymap.set('n', '<leader>w', ':w<CR>')

--- Escape INSERT mode
vim.keymap.set('i', 'jj', '<esc>')
vim.keymap.set('i', 'jk', '<esc>')
vim.keymap.set('i', 'kk', '<esc>')

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

--- Open netrw file explorer
vim.keymap.set("n", "<leader>pe", vim.cmd.Ex)
vim.keymap.set('n', '<leader>pv', vim.cmd.Vex)
vim.keymap.set('n', '<leader>ps', vim.cmd.Sex)

--- Clear search highlighting
vim.keymap.set('n', '<leader>cs', vim.cmd.nohls)
vim.keymap.set('n', '<Esc>', vim.cmd.nohls)

--- Paste without replacing buffer in VISUAL mode
vim.keymap.set('x', '<leader>p', [["_dP]])

--- Delete character without replacing buffer
vim.keymap.set({ 'n', 'x' }, 'x', [["_x]])

--- Yank to system keyboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])

--- Yank contents of entire file to system clipboard
vim.keymap.set('n', '<leader>Y', [[gg"+yG]])

--- Globally rename word cursor is on
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

--- Make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

--- Move VISUAL highlighted region up or down
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")

--- Attemp to format current buffer
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format current buffer" })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--- Create new line while in insert mode
vim.keymap.set('i', '/n', '<C-o>o', { desc = 'Create new line under current line' })

--- Helps with accidently trying a keymap in the wrong mode
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

--- Diagnostic keymaps (from kickstart)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

--- Helpful window navigation commands (from kickstart)
vim.keymap.set('n', '<Left>', '<C-w>h', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<Right>', '<C-w>l', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<Down>', '<C-w>j', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<Up>', '<C-w>k', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<C-Left>', '<C-w><', { desc = 'Decrease the width of the current window' })
vim.keymap.set('n', '<C-Right>', '<C-w>>', { desc = 'Increase the width of the current window' })
vim.keymap.set('n', '<C-Down>', '<C-w>-', { desc = 'Decrease the height of the current window' })
vim.keymap.set('n', '<C-Left>', '<C-w>+', { desc = 'Increase the height of the current window' })

--- Create interactive terminals
vim.keymap.set("n", "<leader>t", "<cmd>terminal<CR>i", { desc = "Open [t]erminal in current window" })
vim.keymap.set("n", "<leader>ts", "<cmd>split | terminal<CR>i", { desc = "Open [t]erminal in a [s]plit window" })
vim.keymap.set("n", "<leader>tv", "<cmd>vsplit | terminal<CR>i",
  { desc = "Open [t]erminal in a [v]ertical split window" })

--- :make keymaps
vim.keymap.set('n', '<leader>mm', vim.cmd.make, { desc = 'Run [m]ake' })
vim.keymap.set('n', '<leader>mM', '<cmd>make % -o %<.exe<CR>', { desc = 'Run [M]ake on current file' })
vim.keymap.set('n', '<leader>mR', '<cmd>!%<.exe<CR>', { desc = '[R]un current file' })
vim.keymap.set('n', '<leader>mE', '<cmd>make % -o %<.exe && %<.exe<CR>',
  { desc = 'Run [M]ake on current file and [E]xecute' })
vim.keymap.set('n', '<leader>mc', '<cmd>make clean<CR>', { desc = '[m]ake [c]lean' })
vim.keymap.set('n', '<leader>mr', '<cmd>make run<CR>', { desc = 'Run [m]ake [r]un' })
vim.keymap.set('n', '<leader>mb', '<cmd>make build<CR>', { desc = 'Run [m]ake [b]uild' })
vim.keymap.set('n', '<leader>mt', '<cmd>make test<CR>', { desc = 'Run [m]ake [t]est' })
vim.keymap.set('n', '<leader>md', '<cmd>make debug<CR>', { desc = 'Run [m]ake [d]ebug' })

--- :!just keymaps
vim.keymap.set('n', '<leader>jr', '<cmd>split | terminal just run<CR>i', { desc = '[j]ust [r]un' })
vim.keymap.set('n', '<leader>jd', '<cmd>split | terminal just dev<CR>i', { desc = '[j]ust [d]ev' })
vim.keymap.set('n', '<leader>jl', '<cmd>!just list<CR>', { desc = '[j]ust [l]ist' })
