-- disabled
--
if true then
  return {}
end

return {
  "supermaven-inc/supermaven-nvim",
  lazy = false,
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<A-Space>",
      },
      color = {
        suggestion_color = "#53BDA5",
        cterm = 244,
      },
      log_level = "info",
      -- disable_inline_completion = true,
      -- disable_keymaps = true,
    })
  end,
}
