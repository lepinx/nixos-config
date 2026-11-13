vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- TypeScript server. LazyVim 16 already defaults to vtsls (the VS Code
-- implementation, built on tsserver); pinning it here makes the choice explicit
-- and versioned instead of inherited. The other implementation,
-- typescript-language-server, is deliberately not installed: two TS clients on
-- the same buffer means duplicate diagnostics and duplicate code actions.
vim.g.lazyvim_ts_lsp = "vtsls"

vim.opt.exrc = true
vim.opt.relativenumber = true
vim.opt.list = false
vim.opt.winborder = "rounded"
