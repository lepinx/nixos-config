local render_markdown_plugin = vim.env.NVIM_RENDER_MARKDOWN_PLUGIN

if not render_markdown_plugin or render_markdown_plugin == "" then
  return {}
end

return {
  {
    dir = render_markdown_plugin,
    name = "render-markdown.nvim",
    ft = { "markdown" },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>", ft = "markdown", desc = "Toggle Markdown render" },
    },
    opts = {
      completions = {
        lsp = { enabled = true },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },
}
