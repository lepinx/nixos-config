return {
  {
    "sindrets/diffview.nvim",
    opts = {
      view = {
        default = { disable_diagnostics = true },
        file_history = { disable_diagnostics = true },
      },
      hooks = {
        diff_buf_win_enter = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.breakindent = true
          vim.opt_local.smoothscroll = true
          vim.opt_local.showbreak = "↳ "
        end,
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
