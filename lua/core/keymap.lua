-- 使用 Ctrl + 方向键 直接切换窗口
vim.api.nvim_set_keymap("n", "<C-Left>", "<C-w>h", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<C-Right>", "<C-w>l", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<C-Up>", "<C-w>k", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<C-Down>", "<C-w>j", {noremap = true, silent = true})

-- 用来关掉neotree
vim.keymap.set('n', 'q', '<cmd>q!<cr>', { desc = "Close window" })
