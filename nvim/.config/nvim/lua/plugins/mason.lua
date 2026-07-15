-- ~/.config/nvim/lua/plugins/mason.lua

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "markdown-oxide",
      },
    },
  },
}
