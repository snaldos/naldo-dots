---@alias ThemeBackend "tokyonight" | "matugen" | "base16"

---@type ThemeBackend
local backend = "tokyonight"

return {
  backend = backend,

  base16 = {
    colorscheme = "base16-rose-pine",
  },

  tokyonight = {
    opts = {
      style = "moon",
      transparent = true,
    },
  },
}
