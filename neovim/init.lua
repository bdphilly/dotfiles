-- bootstrap lazy.nvim, LazyVim and your plugins

-- Example: Setting debounce for autocmds
-- vim.cmd([[
--   autocmd CursorHold * lua require('vim.lsp').buf_request(0, 'textDocument/hover', {debounce = 100})
-- ]])
--

if vim.g.vscode then
  print("vscode vim!")
  require("config.vscode")
  -- require("lua/config/vscode.lua")
  -- require("config.vscode")
else
  print("normal vim!")
  require("config.lazy")
end

local function print_plugins()
  local plugins = require("lazy").plugins()
  for _, plugin in pairs(plugins) do
    if plugin.url ~= nil then
      print(plugin.url .. "\n")
    end
  end
end
-- print_plugins() -- Comment or uncomment to toggle the output
