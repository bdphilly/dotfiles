return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
    config = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<cmd-d>",
        ["Find Subword Under"] = "<cmd-d>",
      }
      -- Optionally, you can add more configuration here
    end,
  },
}
