local sqlfluff_root = vim.fs.normalize(vim.fn.expand("~/workspace/sql"))

local function is_sqlfluff_project(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return false
  end

  return vim.startswith(vim.fs.normalize(filename), sqlfluff_root .. "/")
end

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.sql = function(bufnr)
        return is_sqlfluff_project(bufnr) and { "sqlfluff" } or { "sql_formatter" }
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("user-sql-lint", { clear = true }),
        pattern = "*.sql",
        callback = function(args)
          if is_sqlfluff_project(args.buf) then
            lint.try_lint("sqlfluff")
          end
        end,
      })
    end,
  },
  {
    "tpope/vim-dadbod",
    cmd = "DB",
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql", "pgsql" },
    dependencies = { "tpope/vim-dadbod" },
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
          buffer = {
            enabled = function()
              return not vim.b.sql_disable_buffer_completion
            end,
          },
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
}
