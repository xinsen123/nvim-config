vim.api.nvim_set_keymap("n", "<c-t>", "<cmd>ToggleTerm<CR>", {noremap = true, silent = true}) -- 设置ctrl + t调用终端

require("toggleterm").setup{
  shade_terminals = true,   -- 开启背景阴影/半透明效果
  insert_mappings = true, 
  terminal_mappings = true,

  size = 20,

  on_open = function(term)
    -- 1. 映射 Esc 退出终端模式
    -- 2. 退出后自动执行 wincmd p (切换到上一个活动窗口)
    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", [[<C-\><C-n><C-w>p]], {noremap = true, silent = true})
  end,
}
