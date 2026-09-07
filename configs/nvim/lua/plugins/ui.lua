local lazygit_win = { width = 0.90, height = 0.90 }

return {
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        hover = {
          silent = true,
        },
      },
      presets = {
        lsp_doc_border = true,
      },
    },
    keys = {
      { "<c-f>", false, mode = { "i", "n", "s" } },
      { "<c-b>", false, mode = { "i", "n", "s" } },
    },
  },
  {
    "snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = { layout = { position = "right" } },
          },
        },
      },
      indent = { enabled = false },
      scroll = { enabled = false },
      scope = { enabled = false },
      terminal = {
        shell = { "fish" },
      },
      lazygit = {
        win = {
          style = "lazygit",
          width = lazygit_win.width,
          height = lazygit_win.height,
        },
        env = {
          SHELL = vim.fn.exepath("fish"),
        },
        config = {
          os = {
            editPreset = "nvim-remote",
            editInTerminal = false,
          },
        },
      },
    },
    keys = {
      { "<leader>gd", false },
      { "<leader>gD", false },
      { "<leader>gh", function() require("snacks").picker.git_diff() end, desc = "Git Diff (hunks)" },
    },
  },
}
