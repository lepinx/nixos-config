return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      styles = {
        comments = "italic",
        keywords = "italic",
      },
      highlights = {
        LspInlayHint = { fg = "#6b7280", italic = true },
      },
      plugins = {
        lsp_semantic_tokens = true,
        treesitter = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark_dark",
    },
  },
}
