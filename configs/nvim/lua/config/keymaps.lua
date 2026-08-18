local map = vim.keymap.set

local function set_terminal_and_comment_keymaps()
  map("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
  map("x", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })
  map("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
  map("x", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
  map("t", "<C-/>", "<Nop>", { desc = "Disabled terminal toggle" })
  map("t", "<C-_>", "<Nop>", { desc = "Disabled terminal toggle" })
end

map("n", "<leader>[", "zc", { desc = "Close fold" })
map("n", "<leader>]", "zo", { desc = "Open fold" })

-- LazyVim claims Ctrl+/ and Ctrl+_ for Snacks after this file is initially
-- sourced. Apply the comment mappings again once all defaults are installed.
set_terminal_and_comment_keymaps()
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = set_terminal_and_comment_keymaps,
})

map({ "n", "t" }, "<C-`>", function()
  require("snacks").terminal()
end, { desc = "Toggle terminal" })
