local vars = require("hyprland.variables")

local function file_exists(path)
  local file = io.open(path, "r")
  if file == nil then
    return false
  end

  file:close()
  return true
end

-- Core configuration.
require("hyprland.env")
require("hyprland.autostart")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.keybinds")

-- Generated integrations.
if file_exists(vars.config_dir .. "/workspaces.lua") then
  require("workspaces")
end
if file_exists(vars.config_dir .. "/monitors.lua") then
  require("monitors")
end
if file_exists(vars.config_dir .. "/noctalia.lua") then
  require("noctalia").apply_theme()
end

-- Plugin configuration is isolated so a missing plugin cannot block the core config.
if file_exists(vars.config_dir .. "/hyprland/plugins.lua") then
  require("hyprland.plugins")
end
