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

local indent_size = 4

local function apply_four_space_indent(bufnr)
  vim.bo[bufnr].expandtab = true
  vim.bo[bufnr].shiftwidth = indent_size
  vim.bo[bufnr].tabstop = indent_size
  vim.bo[bufnr].softtabstop = indent_size
end

local function format_buffer(bufnr, async)
  vim.lsp.buf.format({
    bufnr = bufnr,
    async = async,
    formatting_options = {
      tabSize = indent_size,
      insertSpaces = true,
    },
  })
end

vim.api.nvim_create_user_command("Format", function()
  format_buffer(vim.api.nvim_get_current_buf(), true)
end, { desc = "Format current buffer" })

-- Neovim 0.11+ 默认 LSP 快捷键: K(悬停) grn(重命名) gra(代码操作) gri(实现) grr(引用) <C-S>(签名)
-- 此处仅添加无默认映射的额外快捷键
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    apply_four_space_indent(bufnr)

    local map = function(lhs, rhs)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
    end
    map("<leader>f", function() format_buffer(bufnr, true) end)
    map("<leader>e", vim.diagnostic.open_float)
    map("<leader>q", vim.diagnostic.setloclist)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(ev)
    apply_four_space_indent(ev.buf)
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
      ["<Down>"] = cmp.mapping.select_next_item(),
      ["<Up>"] = cmp.mapping.select_prev_item(),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm({ select = true })
          return
        end

        fallback()
      end, { "i", "s" }),
      ["<CR>"] = cmp.mapping(function(fallback)
        local ok_pairs, mini_pairs = pcall(require, "mini.pairs")
        if ok_pairs then
          vim.api.nvim_feedkeys(mini_pairs.cr(), "in", false)
          return
        end

        fallback()
      end, { "i", "s" }),
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
    -- Chisel/Scala 2.13 为主，统一交给全局 scalafmt 配置使用 4 空格缩进
    scalafmtConfigPath = vim.fn.stdpath("config") .. "/.scalafmt.conf",
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


-- hex配置
return {
  "RaafatTurki/hex.nvim", -- 插件仓库地址
  event = "VeryLazy",      -- 延迟加载，在 Neovim 启动后加载
  dependencies = {
    "nvim-lua/plenary.nvim", -- hex.nvim 依赖，确保已安装
  },
  config = function()
    -- 主配置函数
    require("hex").setup({
      -- 1. 核心命令配置
      dump_cmd = "xxd -g 1 -u",    -- 将二进制转为十六进制的命令
      -- -g 1: 每个字节之间显示一个空格
      -- -u: 使用大写十六进制字母
      assemble_cmd = "xxd -r",     -- 将十六进制转回二进制的命令

      -- 2. 二进制文件自动检测逻辑
      -- 在文件读取前判断（可根据文件名）
      is_buf_binary_pre_read = function()
        local filename = vim.fn.expand("%:t") -- 获取当前文件名（不含路径）
        -- 定义需要自动使用 Hex 模式的文件扩展名
        local binary_extensions = {
          "bin", "exe", "dll", "so", "o", "a", "lib", "dat", "img", "iso"
        }
        -- 检查文件名是否以这些扩展名结尾（不区分大小写）
        for _, ext in ipairs(binary_extensions) do
          if filename:lower():match("%.?" .. ext .. "$") then
            return true
          end
        end
        return false -- 默认不是二进制文件
      end,

      -- 在文件读取后判断（可根据文件内容，例如查找 NULL 字节）
      is_buf_binary_post_read = function()
        -- 这个函数在文件内容加载后执行
        -- 可以搜索 NULL 字节（0x00）来判断是否为二进制
        -- 但请注意：某些文本文件也可能包含 NULL 字节
        local null_byte_found = vim.fn.search("\\%x00", "nw") > 0
        return null_byte_found
      end,

      -- 3. 其他可选配置（保持默认即可，通常无需修改）
      -- 你可以在这里添加其他 hex.nvim 提供的配置项
      -- 例如：
      -- highlight_bytes = true, -- 高亮字节
    })

    -- 4. 设置快捷键映射（可选，但强烈推荐）
    -- 使用 vim.keymap.set 进行键位映射
    local map = vim.keymap.set
    local opts = { silent = true, noremap = true, desc = "Hex: Toggle View" }

    -- 在普通模式下，按 <leader>H 切换十六进制/文本视图
    -- 假设你的 leader 键是空格（在 core/options.lua 中设置）
    map("n", "<leader>H", "<cmd>HexToggle<CR>", opts)

    -- 你还可以为 HexDump 和 HexAssemble 设置单独的快捷键
    -- map("n", "<leader>hd", "<cmd>HexDump<CR>", { desc = "Hex: Dump to Hex" })
    -- map("n", "<leader>ha", "<cmd>HexAssemble<CR>", { desc = "Hex: Assemble to Binary" })

  end,
}
