local ok, matugen = pcall(require, "generated.matugen")

if ok then
  matugen.setup()
else
  local theme = require("config.theme")
  require("tokyonight").load(theme.tokyonight.opts)
  vim.notify("Noctalia theme is unavailable; using Tokyo Night", vim.log.levels.WARN)
end
