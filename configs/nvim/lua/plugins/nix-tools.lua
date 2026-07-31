local nix_lsp_servers = {
  "cssls",
  "gopls",
  "html",
  "jsonls",
  "lua_ls",
  "nil_ls",
  "pyright",
  "rust_analyzer",
  "taplo",
  "vtsls",
}

local function normal_file_buffer(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and not name:match("^diffview://") and vim.bo[bufnr].buftype == ""
end

return {
  {
    "mason-org/mason.nvim",
    build = false,
    opts = function(_, opts)
      opts.ensure_installed = {}
      opts.PATH = "skip"
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_enable = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.gopls = vim.tbl_deep_extend("force", opts.servers.gopls or {}, {
        root_dir = function(bufnr, on_dir)
          if not normal_file_buffer(bufnr) then
            return
          end

          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, "go.work") or vim.fs.root(fname, "go.mod") or vim.fs.root(fname, ".git")
          on_dir(root)
        end,
      })

      for _, server in ipairs(nix_lsp_servers) do
        opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, {
          mason = false,
        })
      end
    end,
  },
}
