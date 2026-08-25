local render_markdown_plugin = vim.env.NVIM_RENDER_MARKDOWN_PLUGIN

if not render_markdown_plugin or render_markdown_plugin == "" then
  return {}
end

return {
  {
    dir = render_markdown_plugin,
    name = "render-markdown.nvim",
    -- Snacks uses this renderer from its picker preview before a Markdown
    -- FileType event is emitted, so it must be configured at startup.
    lazy = false,
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>", ft = "markdown", desc = "Toggle Markdown render" },
    },
    opts = {
      -- Snacks renders picker previews in temporary buffers. Depending on
      -- the previewer they are either `nofile` or unlisted, but neither is a
      -- document render-markdown should attach to.
      ignore = function(buf)
        return vim.bo[buf].buftype == "nofile" or not vim.bo[buf].buflisted
      end,
      completions = {
        lsp = { enabled = true },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },
}
