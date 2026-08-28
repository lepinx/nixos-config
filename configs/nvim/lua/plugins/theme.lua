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
        Cursor = { fg = "#000000", bg = "#61afef" },
        Visual = { bg = "#303b4a" },
        FloatBorder = { fg = "#abb2bf" },
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
