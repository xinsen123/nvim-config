-- 基础界面与缩进设置
vim.o.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.smartindent = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"

-- WSL 下通过系统剪贴板和 Windows 互通复制粘贴
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

local function transparent()
  -- 把常见高亮组背景清空，配合透明主题使用
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

-- 主题配置
require("tokyonight").setup({
  transparent = true,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
  },
  sidebars = { "qf", "help", "terminal", "neo-tree" },
})
vim.cmd("colorscheme tokyonight")

-- 文件树配置
require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    use_libuv_file_watcher = true,
    filtered_items = {
      hide_gitignored = false,
      hide_hidden = false,
      never_show = {},
    },
  },
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- 空目录启动时自动打开文件树
    if #vim.fn.argv() == 0 then
      require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
    end
  end,
})
