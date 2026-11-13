-- Go support: gopls ships in the Nix profile and LazyVim's lang.go extra brings
-- the plugins. Only the project-root rules and the settings live here.
local function normal_file_buffer(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and not name:match("^diffview://") and vim.bo[bufnr].buftype == ""
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.gopls = vim.tbl_deep_extend("force", opts.servers.gopls or {}, {
        settings = {
          gopls = {
            analyses = {
              ST1000 = false,
            },
          },
        },
        -- A workspace file wins over a single module, and diff windows must not
        -- pull the whole repository in as the root.
        root_dir = function(bufnr, on_dir)
          if not normal_file_buffer(bufnr) then
            return
          end

          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, "go.work") or vim.fs.root(fname, "go.mod")
          if root then
            on_dir(root)
          end
        end,
      })
    end,
  },
}
