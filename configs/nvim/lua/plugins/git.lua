return {
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      { "]h", function() require("gitsigns").nav_hunk("next") end, desc = "Next Git hunk" },
      { "[h", function() require("gitsigns").nav_hunk("prev") end, desc = "Previous Git hunk" },
      {
        "<leader>hp",
        function() require("gitsigns").preview_hunk() end,
        desc = "Preview Git hunk",
      },
      { "<leader>hs", function() require("gitsigns").stage_hunk() end, desc = "Stage Git hunk" },
      { "<leader>hr", function() require("gitsigns").reset_hunk() end, desc = "Reset Git hunk" },
      {
        "<leader>hb",
        function() require("gitsigns").blame_line({ full = true }) end,
        desc = "Blame Git line",
      },
      { "<leader>hS", function() require("gitsigns").stage_buffer() end, desc = "Stage Git buffer" },
      { "<leader>hR", function() require("gitsigns").reset_buffer() end, desc = "Reset Git buffer" },
      { "<leader>hs", ":Gitsigns stage_hunk<CR>", mode = "v", desc = "Stage selected Git hunk" },
      { "<leader>hr", ":Gitsigns reset_hunk<CR>", mode = "v", desc = "Reset selected Git hunk" },
    },
  },
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
          vim.opt_local.showbreak = ""
          vim.opt_local.foldenable = false
          vim.opt_local.foldlevel = 99
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
