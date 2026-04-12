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
-- WSL剪贴板集成
vim.g.clipboard = {
  name = 'WslClipboard',
  copy = {
    ['+'] = 'clip.exe',
    ['*'] = 'clip.exe',
  },
  paste = {
    ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}
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
  sidebars = { "qf", "help", "terminal", "NvimTree", "neo-tree" },
})
vim.cmd("colorscheme tokyonight")

-- neo-tree设置
require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    use_libuv_file_watcher = true,  -- 实时更新文件树
	filtered_items = {
        hide_gitignored = false,   -- 关键：不隐藏 .gitignore 中的文件
        hide_hidden = false,       -- 不隐藏系统标记的隐藏文件
        -- 可选：明确指定不隐藏 .vh 文件
        never_show = {},           -- 确保这里没有 .vh
      },
  }
})

-- 开机自启文件侧边栏
vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Open Neo-tree automatically on startup",
  callback = function()
    if #vim.fn.argv() == 0 then
      require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
    end
  end,
})

-- 主题测试命令 (临时)
-- 取消注释以下行来测试不同主题，或使用 :lua require('core.ui').switch_theme('theme_name')
-- 注意：需要先安装对应插件 (已在plugins.lua中添加)

-- catppuccin 配置 (可选)
-- require("catppuccin").setup({ transparent = true })
-- vim.cmd("colorscheme catppuccin")

-- nord 配置 (可选)
-- require("nord").setup({ transparent = true })
-- vim.cmd("colorscheme nord")

-- everforest 配置 (可选)
-- vim.g.everforest_transparent_background = 1
-- vim.cmd("colorscheme everforest")

-- rose-pine 配置 (可选)
-- require('rose-pine').setup({ disable_background = true })
-- vim.cmd("colorscheme rose-pine")

-- kanagawa 配置 (可选)
-- require('kanagawa').setup({ transparent = true })
-- vim.cmd("colorscheme kanagawa")

-- 快速切换命令
local M = {}
function M.switch_theme(name)
  if name == "catppuccin" then
    require("catppuccin").setup({ transparent = true })
    vim.cmd("colorscheme catppuccin")
  elseif name == "nord" then
    require("nord").setup({ transparent = true })
    vim.cmd("colorscheme nord")
  elseif name == "everforest" then
    vim.g.everforest_transparent_background = 1
    vim.cmd("colorscheme everforest")
  elseif name == "rose-pine" then
    require('rose-pine').setup({ disable_background = true })
    vim.cmd("colorscheme rose-pine")
  elseif name == "kanagawa" then
    require('kanagawa').setup({ transparent = true })
    vim.cmd("colorscheme kanagawa")
  elseif name == "tokyonight" then
    require("tokyonight").setup({ transparent = true })
    vim.cmd("colorscheme tokyonight")
  else
    print("未知主题: " .. name)
  end
end

-- 创建命令
vim.api.nvim_create_user_command("ThemeSwitch", function(opts)
  M.switch_theme(opts.args)
end, { nargs = 1, complete = function() return { "catppuccin", "nord", "everforest", "rose-pine", "kanagawa", "tokyonight" } end })

-- 提示：使用 :ThemeSwitch catppuccin 切换主题
