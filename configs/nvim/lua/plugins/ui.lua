return {
  {
    "folke/noice.nvim",
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
