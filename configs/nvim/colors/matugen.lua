-- Wraps the noctalia-generated base16 palette as a real colorscheme so the
-- ColorScheme event fires and highlight autocmds re-apply.
vim.cmd("hi clear")
if vim.fn.exists("g:syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "matugen"

require("matugen").setup()
