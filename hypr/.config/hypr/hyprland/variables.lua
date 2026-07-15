local shell = require("hyprland.lib.shell")

local home = assert(os.getenv("HOME"), "HOME is not set")
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local config_dir = config_home .. "/hypr"
local scripts_dir = config_dir .. "/scripts"

local scripts = {
  annotated_snip = scripts_dir .. "/annotated_snip.sh",
  app_launcher = scripts_dir .. "/app_launcher.sh",
  center_scrolling_active = scripts_dir .. "/center_scrolling_active.sh",
  launch_terminal = scripts_dir .. "/launch_terminal.sh",
  scripts_launcher = scripts_dir .. "/scripts_launcher.sh",
  snip_to_search = scripts_dir .. "/snip_to_search.sh",
  theme_launcher = scripts_dir .. "/theme_launcher.sh",
}

local noctalia = {
  executable = "noctalia",
  ipc_subcommand = "msg",
}

---@alias HyprlandMachineProfile "desktop"|"laptop"

local valid_machine_profiles = {
  desktop = true,
  laptop = true,
}

local machine_profile_path = config_dir .. "/machine/profile"
---@type HyprlandMachineProfile
local machine_profile = "laptop"
local machine_profile_file = io.open(machine_profile_path, "r")

-- This file is intentionally gitignored so each machine can choose its own profile.
if machine_profile_file ~= nil then
  machine_profile = machine_profile_file:read("*a") or ""
  machine_profile_file:close()
  machine_profile = machine_profile:match("^%s*(.-)%s*$")
end

assert(
  valid_machine_profiles[machine_profile],
  ("machine profile in %s must be desktop or laptop, got %q"):format(machine_profile_path, machine_profile)
)

local centered_floating_size = "(monitor_w*0.30) (monitor_h*0.70)"
local workspace_monitors = { "DP-1" }

if machine_profile == "laptop" then
  centered_floating_size = "(monitor_w*0.70) (monitor_h*0.85)"
  workspace_monitors = { "eDP-1" }
end

local window = {
  centered_floating_size = centered_floating_size,
}

local terminal_executable = "ghostty"
-- Normal launches keep Ghostty's default app ID; only floating launches use a derived ID.
local terminal_app_id = "com.mitchellh.ghostty"
local terminal_float_app_id = terminal_app_id .. ".float"

local function terminal_command(app_id, ...)
  return shell.command(scripts.launch_terminal, "--terminal", terminal_executable, "--app-id", app_id, "--", ...)
end

local terminal = {
  executable = terminal_executable,
  app_id = terminal_app_id,
  float_app_id = terminal_float_app_id,
  command = terminal_command(terminal_app_id),
}

local scrolling_direction = "right"
assert(scrolling_direction == "left" or scrolling_direction == "right", "scrolling direction must be left or right")
local scrolling_direction_is_left = scrolling_direction == "left"

---@class HyprlandVariables
---@field config_dir string
---@field machine_profile HyprlandMachineProfile
---@field main_mod string
---@field noctalia HyprlandNoctaliaConfig
---@field window HyprlandWindowConfig
---@field terminal HyprlandTerminalConfig
---@field file_manager string
---@field scripts HyprlandScriptPaths
---@field workspace_group_size integer
---@field workspace_monitors string[]
---@field scrolling HyprlandScrollingConfig

---@class HyprlandNoctaliaConfig
---@field executable string
---@field ipc_subcommand string

---@class HyprlandWindowConfig
---@field centered_floating_size string

---@class HyprlandTerminalConfig
---@field executable string
---@field app_id string
---@field float_app_id string
---@field command string

---@class HyprlandScriptPaths
---@field annotated_snip string
---@field app_launcher string
---@field center_scrolling_active string
---@field launch_terminal string
---@field scripts_launcher string
---@field snip_to_search string
---@field theme_launcher string

---@class HyprlandScrollingConfig
---@field direction string
---@field move_col table<string, string>
---@field swap_col table<string, string>
---@field consume_or_expel table<string, string>

---@type HyprlandVariables
local M = {
  config_dir = config_dir,
  machine_profile = machine_profile,
  main_mod = "SUPER",
  noctalia = noctalia,
  window = window,
  terminal = terminal,
  file_manager = terminal_command(terminal_app_id, "fish", "-c", "y"),
  scripts = scripts,
  workspace_group_size = 5,
  workspace_monitors = workspace_monitors,
  scrolling = {
    direction = scrolling_direction,
    move_col = {
      left = scrolling_direction_is_left and "-col" or "+col",
      right = scrolling_direction_is_left and "+col" or "-col",
      prev = scrolling_direction_is_left and "-col" or "+col",
      next = scrolling_direction_is_left and "+col" or "-col",
    },
    swap_col = {
      left = scrolling_direction_is_left and "r" or "l",
      right = scrolling_direction_is_left and "l" or "r",
    },
    consume_or_expel = {
      left = scrolling_direction_is_left and "next" or "prev",
      right = scrolling_direction_is_left and "prev" or "next",
    },
  },
}

return M
