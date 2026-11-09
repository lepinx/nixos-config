local function normal_file_buffer(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and not name:match("^diffview://") and vim.bo[bufnr].buftype == ""
end

return {
  -- Every LSP server comes from Nix (PATH) or the project devShell, so mason has
  -- nothing to install. LazyVim pulls it in; disable it instead of leaving an
  -- installed plugin whose only effect is a dead `:Mason` command.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
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

      opts.servers.just = {}

      -- nil: archive flake inputs automatically instead of prompting "Fetch
      -- them now?" every time an input is missing from the eval cache.
      opts.servers.nil_ls = vim.tbl_deep_extend("force", opts.servers.nil_ls or {}, {
        settings = {
          ["nil"] = {
            nix = {
              flake = { autoArchive = true },
            },
          },
        },
      })
    end,
  },
}
