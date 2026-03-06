-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- vim.keymap.set(
--   "n",
--   "<leader>sx",
--   require("telescope.builtin").resume,
--   { noremap = true, silent = true, desc = "Resume" }
-- )

vim.keymap.set("v", "<C-c>", "y")
vim.keymap.set("v", "<cmd-c>", "y")

-- BP - don't think this is working
-- CMD-S to save buffer
-- Then in wezterm, we need to rebind <cmd-s> to send char '0xAA` to neovim.
vim.keymap.set("n", "<Char-0xAA>", "<cmd>write<cr>", {
  desc = "N: Save current file by <command-s>",
})

-- vscode multicursor. add current word range and goto next
-- vim.keymap.set("n", "<cmd-d>", "mciw*<Cmd>nohl<CR>", { remap = true })

-- don't yank with d
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("v", "d", '"_d')
