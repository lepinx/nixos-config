return {
  {
    "sindrets/diffview.nvim",
    opts = {
      view = {
        default = { disable_diagnostics = true },
        file_history = { disable_diagnostics = true },
      },
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Open diff view" },
      { "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
      { "<leader>gF", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
      { "<leader>gR", "<cmd>DiffviewFileHistory<CR>", desc = "Repo history" },
    },
  },
}
