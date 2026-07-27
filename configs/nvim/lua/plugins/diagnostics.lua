return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user-diagnostics", { clear = true }),
        callback = function()
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#ff5370", bg = "#3b1018", bold = true })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#ffcb6b", bg = "#352a13" })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#82aaff", bg = "#14243b" })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#c3e88d", bg = "#203019" })
          vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#2a0f14" })
        end,
      })
    end,
    opts = function(_, opts)
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
        severity_sort = true,
        underline = false,
        signs = {
          linehl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
          },
        },
        virtual_text = {
          prefix = "!",
          spacing = 2,
          source = "if_many",
        },
      })
    end,
  },
}
