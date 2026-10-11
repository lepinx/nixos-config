-- Stable colorscheme wrapper around the noctalia-generated base16 palette.
--
-- noctalia regenerates lua/matugen.lua on every theme change; this file is
-- owned by the repository and never overwritten. Loaded via
-- :colorscheme matugen (see plugins/theme.lua) so the ColorScheme event
-- fires and autocmds (diagnostic undercurls, plugin highlights) re-apply.
vim.cmd("hi clear")
if vim.fn.exists("g:syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "matugen"

require("matugen").setup()
