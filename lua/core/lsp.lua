-- lua/core/lsp.lua
-- =============================
-- Unified LSP setup for Neovim ≥ 0.11.x
-- Supports: C/C++, Verilog
-- Easily extensible for other languages
-- =============================

-- 修正 Verilog 文件类型识别
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.v", "*.sv" },
  callback = function()
    vim.bo.filetype = "verilog"
  end,
})



vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- 通用 on_attach
local function on_attach(_, bufnr)
  local map = function(m, lhs, rhs)
    vim.keymap.set(m, lhs, rhs, { buffer = bufnr, silent = true })
  end
  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "gD", vim.lsp.buf.declaration)
  map("n", "gi", vim.lsp.buf.implementation)
  map("n", "K", vim.lsp.buf.hover)
  map("n", "<leader>rn", vim.lsp.buf.rename)
  map("n", "<leader>ca", vim.lsp.buf.code_action)
  map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end)
  map("n", "[d", vim.diagnostic.goto_prev)
  map("n", "]d", vim.diagnostic.goto_next)
  map("n", "<leader>e", vim.diagnostic.open_float)
  map("n", "<leader>q", vim.diagnostic.setloclist)
end

-- 自动寻找项目根目录
local function pick_root()
  local markers = { ".git", "Makefile", "CMakeLists.txt", "compile_commands.json", "compile_flags.txt" }
  local found = vim.fs.root(0, markers)
  if found then return found end
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then return vim.fs.dirname(bufname) end
  return vim.loop.cwd()
end

-- 语言服务器列表（可拓展）
local servers = {
  clangd = {
    filetypes = { "c", "cpp", "objc", "objcpp" },
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/clangd", "--background-index", "--clang-tidy" },
  },

  svlangserver = {
    filetypes = { "verilog", "systemverilog" },
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/svlangserver" },
	init_options = {
    triggerCharacters = { ".", "#", "(", ",", "=", ":" },
  },
  },
}

-- 启动函数（通用）
local function start_server(name, cfg)
  -- Mason路径检测
  if vim.fn.executable(cfg.cmd[1]) == 0 then
    cfg.cmd[1] = name
  end
  vim.lsp.start({
    name = name,
    cmd = cfg.cmd,
    root_dir = pick_root(),
    filetypes = cfg.filetypes,
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

-- 自动启动 LSP
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_flatten(vim.tbl_map(function(k) return servers[k].filetypes end, vim.tbl_keys(servers))),
  callback = function(ev)
    local ft = ev.match
    for name, cfg in pairs(servers) do
      if vim.tbl_contains(cfg.filetypes, ft) then
        local buf = vim.api.nvim_get_current_buf()
        for _, c in pairs(vim.lsp.get_clients({ bufnr = buf })) do
          if c.name == name then return end
        end
        start_server(name, cfg)
        break
      end
    end
  end,
})

-- 用户命令手动安装
vim.api.nvim_create_user_command("LspInstall", function()
  vim.cmd("Mason")
  vim.notify("在 Mason 窗口中安装: clangd 以及 svlangserver", vim.log.levels.INFO)
end, {})

-- nvim-cmp 配置（扩展 Verilog 文件类型）
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  local luasnip_ok, luasnip = pcall(require, "luasnip")

  cmp.setup({
    snippet = {
      expand = function(args)
        if luasnip_ok then luasnip.lsp_expand(args.body) end
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<Tab>"]   = cmp.mapping.select_next_item(),
      ["<S-Tab>"] = cmp.mapping.select_prev_item(),
      ["<CR>"]    = cmp.mapping.confirm({ select = true }),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"]   = cmp.mapping.close(),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "buffer" },
      { name = "path" },
    }),
    window = {
      completion    = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
  })

  -- 针对 Verilog 文件单独设定额外源（可选）
  cmp.setup.filetype("verilog", {
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "buffer" },
      { name = "path" },
      -- 如果未来装了 snippet 插件，可以启用:
      -- { name = "luasnip" },
    }),
  })
end
