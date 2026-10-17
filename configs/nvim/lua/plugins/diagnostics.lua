local hover_win

-- Shared by the init hook and the spec opts: colors come from the colorscheme's
-- Diagnostic* groups, so no hardcoded hexes here.
local diagnostics_config = {
  severity_sort = true,
  underline = true,
  virtual_text = {
    severity = { min = vim.diagnostic.severity.WARN },
    spacing = 2,
    source = "if_many",
    prefix = "●",
    format = function(diagnostic)
      if diagnostic.code then
        return diagnostic.code .. ": " .. diagnostic.message
      end
      return diagnostic.message
    end,
  },
}

local function diagnostic_or_hover()
  if hover_win and vim.api.nvim_win_is_valid(hover_win) then
    vim.api.nvim_win_close(hover_win, true)
    hover_win = nil
    return
  end

  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if #diagnostics == 0 then
    vim.lsp.buf.hover()
    return
  end

  local _, win = vim.diagnostic.open_float(nil, {
    border = "rounded",
    focus = false,
    scope = "line",
    source = "if_many",
    close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre", "WinLeave" },
  })
  hover_win = win
end

return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.diagnostic.config(diagnostics_config)
      local function diagnostic_jump(count, severity)
        return function()
          vim.diagnostic.jump({ count = count, severity = severity })
        end
      end

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "]d", diagnostic_jump(1), { desc = "Next diagnostic" })
      vim.keymap.set("n", "[d", diagnostic_jump(-1), { desc = "Prev diagnostic" })
      vim.keymap.set("n", "]e", diagnostic_jump(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })
      vim.keymap.set("n", "[e", diagnostic_jump(-1, vim.diagnostic.severity.ERROR), { desc = "Prev error" })
      vim.keymap.set("n", "]w", diagnostic_jump(1, vim.diagnostic.severity.WARN), { desc = "Next warning" })
      vim.keymap.set("n", "[w", diagnostic_jump(-1, vim.diagnostic.severity.WARN), { desc = "Prev warning" })
    end,
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers["*"] = vim.tbl_deep_extend("force", opts.servers["*"] or {}, {
        keys = {
          { "K", diagnostic_or_hover, desc = "Hover diagnostics or docs" },
        },
      })
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, diagnostics_config)
    end,
  },
}
