local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },

  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "scalameta/nvim-metals",

  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
  },

  { "akinsho/toggleterm.nvim", version = "*" },

  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  "HiPhish/rainbow-delimiters.nvim",

  { "echasnovski/mini.pairs", version = false, event = "InsertEnter", config = true },

  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "ravitemer/mcphub.nvim"
    }
  }
}, { ui = { border = "rounded" } })
