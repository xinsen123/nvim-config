-- =========================
-- User Interface Config
-- =========================

vim.o.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.smartindent = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"
vim.o.updatetime = 250

-- 透明背景
local function transparent()
  local groups = {
    "Normal", "NormalFloat", "SignColumn", "LineNr", "Folded", "NonText",
    "EndOfBuffer", "StatusLine", "StatusLineNC", "TabLine", "TabLineFill",
    "TabLineSel", "Pmenu", "PmenuSel", "FloatBorder", "MsgArea", "WinSeparator",
  }
  for _, g in ipairs(groups) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
  end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = transparent })
transparent()

-- tokyonight设置
require("tokyonight").setup({
  transparent = true,           -- 主窗口透明
  styles = {
    sidebars = "transparent",   -- 侧边栏也透明（NvimTree, Telescope等）
    floats = "transparent",     -- 浮动窗口透明
  },
  -- 指定哪些窗口被视为侧边栏
  sidebars = { "qf", "help", "terminal", "NvimTree", "neo-tree" },
})

vim.cmd("colorscheme tokyonight")

-- 开机自启文件侧边栏
vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Open Neo-tree automatically on startup",
  callback = function()
    -- 如果没有任何文件被指定打开（即直接启动 nvim），则打开 Neo-tree
    if #vim.fn.argv() == 0 then
      require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
    end
  end,
})

-- nvim其他设置
require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    use_libuv_file_watcher = true,  -- 实时更新文件树
  }
})
