local shell = require("hyprland.lib.shell")

local home = assert(os.getenv("HOME"), "HOME is not set")
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local config_dir = config_home .. "/hypr"
local scripts_dir = config_dir .. "/scripts"
local local_bin_dir = home .. "/.local/bin"
local local_libexec_dir = home .. "/.local/libexec/naldo"

local scripts = {
  annotated_snip = local_bin_dir .. "/naldo-annotated-snip",
  app_launcher = scripts_dir .. "/app_launcher.sh",
  keybind_cheatsheet = scripts_dir .. "/keybind_cheatsheet.sh",
  launch_terminal = local_libexec_dir .. "/launch-terminal",
  layout_selector = scripts_dir .. "/layout_selector.sh",
  scripts_launcher = local_bin_dir .. "/naldo-scripts-menu",
  snip_to_search = local_bin_dir .. "/naldo-snip-to-search",
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

local machine_profile_dir = config_home .. "/naldo/machine-profile"
local machine_profile_path = machine_profile_dir .. "/profile"
local machine_profile_default_path = machine_profile_dir .. "/default"

local function read_machine_profile(path)
  local file = io.open(path, "r")
  if file == nil then
    return nil
  end

  local profile = file:read("*a") or ""
  file:close()
  return profile:match("^%s*(.-)%s*$")
end

local machine_profile = read_machine_profile(machine_profile_path)
local machine_profile_source = machine_profile_path
if machine_profile == nil then
  machine_profile = read_machine_profile(machine_profile_default_path)
  machine_profile_source = machine_profile_default_path
end

assert(machine_profile ~= nil, "machine profile is missing; run ~/dotfiles/install.sh")
---@cast machine_profile HyprlandMachineProfile
assert(
  valid_machine_profiles[machine_profile],
  ("machine profile in %s must be desktop or laptop, got %q"):format(machine_profile_source, machine_profile)
)

---@type HyprlandKeyboardConfig
local keyboard = {
  layout = "us",
  numlock_by_default = true,
  repeat_delay = 250,
  repeat_rate = 35,
}

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
---@field keyboard HyprlandKeyboardConfig
---@field noctalia HyprlandNoctaliaConfig
---@field window HyprlandWindowConfig
---@field terminal HyprlandTerminalConfig
---@field file_manager string
---@field scripts HyprlandScriptPaths
---@field workspace_group_size integer
---@field workspace_monitors string[]
---@field scrolling HyprlandScrollingConfig

---@class HyprlandKeyboardConfig
---@field layout "gb"|"us"
---@field numlock_by_default boolean
---@field repeat_delay integer
---@field repeat_rate integer

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
---@field keybind_cheatsheet string
---@field launch_terminal string
---@field layout_selector string
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
  keyboard = keyboard,
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
