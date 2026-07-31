local map = vim.keymap.set

map("n", "<leader>[", "zc", { desc = "Close fold" })
map("n", "<leader>]", "zo", { desc = "Open fold" })
map("n", ";i", "<cmd>Inspect<CR>", { desc = "Inspect highlight" })
map("n", "<C-d>", "<C-d>", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>", { desc = "Scroll up" })
map("n", "<C-f>", "<C-f>", { desc = "Page down" })
map("n", "<C-b>", "<C-b>", { desc = "Page up" })
