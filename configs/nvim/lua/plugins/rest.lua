return {
  {
    "rest-nvim/rest.nvim",
    version = "v3.13.0",
    ft = { "http" },
    cmd = "Rest",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        if not vim.tbl_contains(opts.ensure_installed, "http") then
          table.insert(opts.ensure_installed, "http")
        end
      end,
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user-rest-json-format", { clear = true }),
        pattern = "json",
        callback = function(args)
          if vim.bo[args.buf].buftype == "nofile" then
            vim.bo[args.buf].formatexpr = ""
            vim.bo[args.buf].formatprg = "jq --indent 2"
          end
        end,
      })
    end,
    keys = {
      { "<leader>rr", "<cmd>Rest run<CR>", ft = "http", desc = "Run HTTP request" },
      { "<leader>ro", "<cmd>Rest open<CR>", ft = "http", desc = "Open HTTP response" },
    },
  },
}
