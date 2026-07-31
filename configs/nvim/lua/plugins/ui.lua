return {
  {
    "snacks.nvim",
    opts = {
      indent = { enabled = false },
      scroll = { enabled = false },
      scope = { enabled = false },
    },
    keys = {
      { "<leader>gd", false },
      { "<leader>gD", false },
      { "<leader>gh", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" },
    },
  },
}
