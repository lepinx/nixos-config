-- One Dark Pro (darker) wins for the editor: syntax highlighting is taste,
-- and the generated M3 palettes are mediocre at it. Noctalia keeps the
-- desktop and terminal tools; matugen stays available via
-- configs/nvim/colors/matugen.lua (frozen, not the default).
return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      options = {
        transparency = true,
      },
      styles = {
        comments = "italic",
        keywords = "italic",
      },
      highlights = {
        LspInlayHint = { fg = "#6b7280", italic = true },
        Cursor = { fg = "#000000", bg = "#61afef" },
        Visual = { bg = "#303b4a" },
        FloatBorder = { fg = "#abb2bf" },
        -- onedarkpro's transparency option skips CursorLine/CursorLineNr/
        -- QuickFixLine: they keep a solid dark bar that clashes with the
        -- ghostty wallpaper blend (oil shows it full width).
        CursorLine = { bg = "NONE" },
        CursorLineNr = { bg = "NONE" },
        QuickFixLine = { bg = "NONE" },
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
