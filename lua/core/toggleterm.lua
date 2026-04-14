vim.api.nvim_set_keymap("n", "<C-t>", "<cmd>ToggleTerm<CR>", { noremap = true, silent = true })

require("toggleterm").setup({
  size = 20,
  on_open = function(term)
    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", [[<C-\><C-n><C-w>p]], { noremap = true, silent = true })
  end,
})
