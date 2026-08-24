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
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = {
          sql = { "snippets", "buffer" },
        },
        providers = {
          buffer = {
            enabled = function()
              return not vim.b.sql_disable_buffer_completion
            end,
          },
        },
      },
    },
  },
}
