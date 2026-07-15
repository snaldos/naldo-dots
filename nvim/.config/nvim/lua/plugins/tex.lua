-- ~/.config/nvim/lua/plugins/tex.lua

return {
  {
    "lervag/vimtex",
    init = function()
      vim.g.vimtex_view_method = "zathura"

      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        continuous = 1,
        callback = 1,
        options = {
          "-pdf",
          "-interaction=nonstopmode",
          "-synctex=1",
        },
      }
    end,
  },
}
