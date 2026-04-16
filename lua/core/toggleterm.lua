-- Ctrl + t 快速开关内置终端
vim.api.nvim_set_keymap("n", "<C-t>", "<cmd>ToggleTerm<CR>", { noremap = true, silent = true })

require("toggleterm").setup({
  size = 20,
  on_open = function(term)
    -- 终端模式下按 Esc 先回到普通模式，再跳回上一个窗口
    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", [[<C-\><C-n><C-w>p]], { noremap = true, silent = true })
  end,
})
