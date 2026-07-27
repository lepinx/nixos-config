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

      for _, server in ipairs(nix_lsp_servers) do
        opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, {
          mason = false,
        })
      end
    end,
  },
}
