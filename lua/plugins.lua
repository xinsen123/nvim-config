-- =========================
-- Plugin definition by lazy.nvim
-- =========================

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 插件列表
require("lazy").setup({
  -- 主题
  { "Mofiqul/vscode.nvim", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {} },
  -- 候选主题 (字体花哨、高亮明显、护眼)
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
  { "shaunsingh/nord.nvim", lazy = false, priority = 1000 },
  { "sainnhe/everforest", lazy = false, priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },

  -- 基础功能与 LSP
  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "scalameta/nvim-metals",

  -- 自动补全
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",

  -- 文件侧边栏
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false, -- neo-tree will lazily load itself
  },

  -- nvim内终端
  { "akinsho/toggleterm.nvim", version = "*", config = true },

  -- 语法高亮与彩虹括号
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  "HiPhish/rainbow-delimiters.nvim",

  -- 简单括号补全
  { "echasnovski/mini.pairs", version = false, event = "InsertEnter", config = function() require("mini.pairs").setup() end },

  -- ai插件
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "ravitemer/mcphub.nvim"
    }
  }
}, { ui = { border = "rounded" } })
