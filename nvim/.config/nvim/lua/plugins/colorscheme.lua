local theme = require("config.theme")

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = theme.tokyonight.opts,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = theme.backend,
    },
  },
}
