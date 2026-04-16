-- 把 Verilog / SystemVerilog 文件识别成对应 filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.v", "*.sv", "*.vh" },
  callback = function()
    vim.bo.filetype = "verilog"
  end,
})

-- 优先使用 Mason 安装的 LSP 可执行文件
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local mason_ok, mason = pcall(require, "mason")
if mason_ok then mason.setup() end

local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if mason_lspconfig_ok then
  mason_lspconfig.setup({
    -- 需要时自动安装这些语言服务器
    ensure_installed = { "clangd", "svlangserver", "jdtls" },
    automatic_installation = true,
  })
end

-- 让补全插件把额外能力注册给 LSP
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp_lsp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- Neovim 0.11+ 默认 LSP 快捷键: K(悬停) grn(重命名) gra(代码操作) gri(实现) grr(引用) <C-S>(签名)
-- 此处仅添加无默认映射的额外快捷键
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(lhs, rhs)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
    end
    map("<leader>f", function() vim.lsp.buf.format({ async = true }) end)
    map("<leader>e", vim.diagnostic.open_float)
    map("<leader>q", vim.diagnostic.setloclist)
  end,
})

local function pick_root(markers)
  -- 尽量从常见工程标记推断项目根目录
  markers = markers or { ".git", "Makefile", "CMakeLists.txt", "compile_commands.json", "compile_flags.txt" }
  local found = vim.fs.root(0, markers)
  if found then return found end
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then return vim.fs.dirname(bufname) end
  return vim.loop.cwd()
end

local servers = {
  -- C/C++ 使用 clangd
  clangd = {
    filetypes = { "c", "cpp", "objc", "objcpp" },
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/clangd", "--background-index", "--clang-tidy" },
  },
  -- Verilog / SystemVerilog 使用 svlangserver
  svlangserver = {
    filetypes = { "verilog", "systemverilog" },
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/svlangserver" },
    init_options = {
      triggerCharacters = { ".", "#", "(", ",", "=", ":" },
    },
  },
  -- Java 使用 jdtls，适合 Gradle / Maven 项目
  jdtls = {
    filetypes = { "java" },
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/jdtls" },
    root_markers = { "gradlew", "mvnw", "settings.gradle", "settings.gradle.kts", "pom.xml", ".git" },
  },
}

local function start_server(name, cfg)
  -- Mason 没装时回退到系统 PATH 中的同名命令
  if vim.fn.executable(cfg.cmd[1]) == 0 then
    cfg.cmd[1] = name
  end
  vim.lsp.start({
    name = name,
    cmd = cfg.cmd,
    root_dir = pick_root(cfg.root_markers),
    filetypes = cfg.filetypes,
    capabilities = capabilities,
  })
end

-- 进入对应 filetype 时按需启动语言服务器，避免重复启动
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

-- 提供一个命令，方便手动打开 Mason 安装界面
vim.api.nvim_create_user_command("LspInstall", function()
  vim.cmd("Mason")
  vim.notify("在 Mason 窗口中安装: clangd、svlangserver 和 jdtls", vim.log.levels.INFO)
end, {})

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  cmp.setup({
    -- 使用 Neovim 内置 snippet 能力展开补全项
    snippet = {
      expand = function(args)
        vim.snippet.expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<Tab>"] = cmp.mapping.select_next_item(),
      ["<S-Tab>"] = cmp.mapping.select_prev_item(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
    }),
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
  })
end

local metals_ok, metals = pcall(require, "metals")
if metals_ok then
  -- Scala 项目进入相关文件时自动挂载 metals
  local metals_config = metals.bare_config()
  metals_config.settings = {
    showImplicitArguments = true,
    excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
  }
  metals_config.init_options = {
    statusBarProvider = "on",
  }
  metals_config.capabilities = capabilities

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "scala", "sbt" },
    callback = function()
      metals.initialize_or_attach(metals_config)
    end,
  })
end
