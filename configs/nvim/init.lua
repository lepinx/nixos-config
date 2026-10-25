require("config.options")
require("config.autocmds")
require("config.lazy")
require("config.keymaps")

-- LazyVim sets nowrap during setup, so apply these after loading it.
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.list = false
