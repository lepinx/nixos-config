local sql_filetypes = { "sql", "mysql", "plsql", "pgsql" }

local function find_up(name, path)
  return vim.fs.find(name, { path = vim.fs.dirname(path), upward = true })[1]
end

local function current_sql_file()
  if vim.bo.buftype ~= "" or vim.fn.expand("%:p") == "" then
    vim.notify("Sqruff needs a saved SQL file", vim.log.levels.WARN)
    return nil
  end

  return vim.fn.expand("%:p")
end

local function show_sqruff_output(title, result)
  local output = vim.trim((result.stdout or "") .. "\n" .. (result.stderr or ""))
  if output == "" then
    vim.notify("Sqruff: no output", vim.log.levels.INFO)
    return
  end

  vim.cmd("botright split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "sqruff://" .. title)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "text"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n", { plain = true }))
end

local function run_sqruff(args)
  if vim.fn.executable("sqruff") ~= 1 then
    vim.notify("sqruff is not available in PATH", vim.log.levels.ERROR)
    return nil
  end

  return vim.system(args, { text = true }):wait()
end

local function sqruff_args(subcommand, extra_args, file)
  local args = { "sqruff" }
  local config = find_up(".sqruff", file)
  if config then
    vim.list_extend(args, { "--config", config })
  end
  table.insert(args, subcommand)
  vim.list_extend(args, extra_args or {})
  table.insert(args, file)
  return args
end

vim.api.nvim_create_user_command("SqruffLint", function()
  local file = current_sql_file()
  if not file then
    return
  end

  local result = run_sqruff(sqruff_args("lint", { "--format", "human" }, file))
  if not result then
    return
  end

  if result.code == 0 then
    vim.notify("Sqruff: no lint issues", vim.log.levels.INFO)
  else
    show_sqruff_output("lint", result)
  end
end, { desc = "Run sqruff lint on the current file", force = true })

vim.api.nvim_create_user_command("SqruffFix", function()
  local file = current_sql_file()
  if not file then
    return
  end

  vim.cmd.write()
  local result = run_sqruff(sqruff_args("fix", { "--format", "human" }, file))
  if not result then
    return
  end

  if result.code == 0 then
    vim.cmd("edit!")
    vim.notify("Sqruff: fixed current file", vim.log.levels.INFO)
  else
    show_sqruff_output("fix", result)
  end
end, { desc = "Run sqruff fix on the current file", force = true })

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.sqlfluff = {
        command = "sqlfluff",
        args = function(_, ctx)
          local args = { "format", "--stdin-filename", ctx.filename }
          local config = find_up(".sqlfluff", ctx.filename)
          if config then
            vim.list_extend(args, { "--config", config })
          else
            vim.list_extend(args, { "--dialect", "ansi" })
          end
          table.insert(args, "-")
          return args
        end,
        stdin = true,
        condition = function(_, ctx)
          return find_up(".sqlfluff", ctx.filename) ~= nil
        end,
      }
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.sql = { "sqlfluff" }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.sql = { "sqlfluff" }
    end,
    config = function(_, opts)
      local lint = require("lint")
      local sqlfluff = lint.linters.sqlfluff

      lint.linters.sqlfluff = function()
        local linter = vim.deepcopy(type(sqlfluff) == "function" and sqlfluff() or sqlfluff)
        local parser = linter.parser
        local file = vim.api.nvim_buf_get_name(0)
        local args = { "lint", "--format=json", "--stdin-filename", file }
        local config = find_up(".sqlfluff", file)

        if config then
          vim.list_extend(args, { "--config", config })
        else
          vim.list_extend(args, { "--dialect", "ansi" })
        end
        table.insert(args, "-")

        linter.args = args
        linter.parser = function(output, bufnr, linter_cwd)
          local diagnostics = parser(output, bufnr, linter_cwd)
          for _, diagnostic in ipairs(diagnostics) do
            if diagnostic.code == "PRS" then
              local line = vim.api.nvim_buf_get_lines(bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1] or ""
              diagnostic.end_lnum = diagnostic.lnum
              diagnostic.end_col = #line
              diagnostic.message = diagnostic.message:gsub("^Line %d+, Position %d+: ", "")
            end
            if #diagnostic.message > 140 then
              diagnostic.message = diagnostic.message:sub(1, 137) .. "..."
            end
          end
          return diagnostics
        end
        return linter
      end

      lint.linters_by_ft = vim.tbl_deep_extend("force", lint.linters_by_ft or {}, opts.linters_by_ft or {})

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("user-sql-lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = sql_filetypes, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>db", "<cmd>DBUIToggle<CR>", desc = "Database UI" },
      { "<leader>df", "<cmd>DBUIFindBuffer<CR>", desc = "Database buffer" },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = {
          sql = { "snippets", "dadbod", "buffer" },
        },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
}
