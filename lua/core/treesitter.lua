-- =========================
-- Treesitter & Rainbow brackets
-- =========================

require("nvim-treesitter.configs").setup({
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "verilog" },
  highlight = { enable = true },
})

vim.g.rainbow_delimiters = {
  strategy = { [''] = require("rainbow-delimiters").strategy.global },
  query = { [''] = 'rainbow-delimiters' },
}

require("mini.pairs").setup()
