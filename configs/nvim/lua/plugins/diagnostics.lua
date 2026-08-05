local hover_win

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
      local diagnostics_config = {
        severity_sort = true,
        underline = true,
        signs = {
          linehl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
            [vim.diagnostic.severity.WARN] = "DiagnosticLineWarn",
          },
        },
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

      local function set_diagnostic_highlights()
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#ff5370", bg = "#3b1018", bold = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#ffcb6b", bg = "#352a13" })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#82aaff", bg = "#14243b" })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#c3e88d", bg = "#203019" })
        vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#2a0f14" })
        vim.api.nvim_set_hl(0, "DiagnosticLineWarn", { bg = "#241f10" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#ff5370" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#ffcb6b" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "#82aaff" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#c3e88d" })
      end

      local function diagnostic_jump(count, severity)
        return function()
          vim.diagnostic.jump({ count = count, severity = severity })
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user-diagnostics", { clear = true }),
        callback = set_diagnostic_highlights,
      })
      set_diagnostic_highlights()
      vim.diagnostic.config(diagnostics_config)
      vim.keymap.set("n", "K", diagnostic_or_hover, { desc = "Hover diagnostics or docs" })
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
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
        severity_sort = true,
        underline = true,
        signs = {
          linehl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
            [vim.diagnostic.severity.WARN] = "DiagnosticLineWarn",
          },
        },
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
      })
    end,
  },
}
