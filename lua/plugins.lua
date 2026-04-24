-- lazy.nvim 的安装路径
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- 本地不存在时自动拉取插件管理器
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 在这里集中声明所有插件
require("lazy").setup({
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },

  -- LSP 与语言服务器管理
  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "scalameta/nvim-metals",
  "RaafatTurki/hex.nvim",

  -- 自动补全
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",

  -- 文件树
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

  -- 语法高亮与彩虹括号
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  "HiPhish/rainbow-delimiters.nvim",

  -- 自动补全括号
  { "echasnovski/mini.pairs", version = false, event = "InsertEnter", config = true },

  -- AI / MCP 相关插件
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "ravitemer/mcphub.nvim"
    }
  },
}, { ui = { border = "rounded" } })
