local map = vim.keymap.set

map("n", "<leader>[", "zc", { desc = "Close fold" })
map("n", "<leader>]", "zo", { desc = "Open fold" })
