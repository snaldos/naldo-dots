return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
  },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      return require("config.theme").tokyonight.opts
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local theme = require("config.theme")
        local ok, err

        if theme.backend == "matugen" then
          ok, err = pcall(function()
            require("config.matugen").setup()
          end)
          if not ok then
            vim.notify(("Failed to apply Noctalia theme: %s; using Tokyo Night"):format(err), vim.log.levels.WARN)
            ok, err = pcall(function()
              require("tokyonight").load(theme.tokyonight.opts)
            end)
          end
        elseif theme.backend == "base16" then
          ok, err = pcall(vim.cmd.colorscheme, theme.base16.colorscheme)
        elseif theme.backend == "tokyonight" then
          ok, err = pcall(function()
            require("tokyonight").load(theme.tokyonight.opts)
          end)
        else
          vim.notify(
            ("Unknown theme backend %q; no colorscheme applied"):format(tostring(theme.backend)),
            vim.log.levels.WARN
          )
          return
        end

        if not ok then
          vim.notify(("Failed to apply %q theme: %s"):format(tostring(theme.backend), err), vim.log.levels.ERROR)
        end
      end,
    },
  },
}
