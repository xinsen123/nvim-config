-- 基础界面与缩进设置
vim.o.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
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

----------------------------------------------------------------------
-- 持久化 neo-tree 展开目录状态（退出保存，启动恢复）
----------------------------------------------------------------------
local state_file = vim.fn.stdpath("data") .. "/neo-tree-expanded.json"

local function save_neotree_state()
  local ok, renderer = pcall(require, "neo-tree.ui.renderer")
  local ok2, manager = pcall(require, "neo-tree.sources.manager")
  if not (ok and ok2) then return end
  local state = manager.get_state("filesystem")
  if state and state.tree then
    local expanded = renderer.get_expanded_nodes(state.tree)
    if expanded and #expanded > 0 then
      local f = io.open(state_file, "w")
      if f then f:write(vim.fn.json_encode(expanded)); f:close() end
    end
  end
end

local function load_neotree_state()
  local ok, data = pcall(function()
    local f = io.open(state_file, "r")
    if not f then return nil end
    local content = f:read("*a"); f:close()
    return vim.fn.json_decode(content)
  end)
  if ok and type(data) == "table" and #data > 0 then
    return data
  end
  return {}
end

-- 关闭 neo-tree 窗口时保存（按 q 关闭触发）
local function setup_save_on_close()
  local ok, events = pcall(require, "neo-tree.events")
  if ok then
    events.subscribe({
      event = events.NEO_TREE_WINDOW_BEFORE_CLOSE,
      handler = save_neotree_state,
    })
  end
end

-- :q / :wq / :wqa 退出时保存（QuitPre 比 VimLeavePre 早触发，树状态还在）
vim.api.nvim_create_autocmd("QuitPre", {
  callback = save_neotree_state,
})

-- 启动时恢复展开目录
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    setup_save_on_close()
    if #vim.fn.argv() == 0 then
      local expanded = load_neotree_state()
      if #expanded > 0 then
        local manager = require("neo-tree.sources.manager")
        local state = manager.get_state("filesystem")
        -- 用 force_open_folders，因为 fs_scan.get_items() 内部会执行：
        --   state.default_expanded_nodes = state.force_open_folders or { state.path }
        state.force_open_folders = expanded
      end
      require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
    end
  end,
})
