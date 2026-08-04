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
      indent = { enabled = false },
      scroll = { enabled = false },
      scope = { enabled = false },
      terminal = {
        shell = { "nu" },
      },
      lazygit = {
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
