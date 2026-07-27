return {
  {
    "stevearc/oil.nvim",
    keys = {
      { "-", "<cmd>Oil --float<CR>", desc = "Open parent directory" },
    },
    opts = {
      columns = { "icon" },
      view_options = {
        show_hidden = true,
      },
    },
  },
}
