-- Layout queries, conditional dispatch, and layout cycling.

---@alias HL.Hyprland.Dispatcher fun(): nil
---@alias HL.Hyprland.DispatcherLike HL.Hyprland.Dispatcher|HL.Dispatcher

---@class HL.Hyprland.LayoutDispatcherSpec
---@field layout string
---@field dispatcher HL.Hyprland.DispatcherLike

---@class HL.Hyprland.FloatingOrLayoutDispatcherSpec
---@field floating HL.Hyprland.DispatcherLike
---@field layouts HL.Hyprland.LayoutDispatcherSpec[]

local M = {}

local available_layouts = { "dwindle", "scrolling" }

---@param dispatcher HL.Hyprland.DispatcherLike|nil
local function run(dispatcher)
  if dispatcher == nil then
    return
  end

  if type(dispatcher) == "function" then
    dispatcher()
  else
    ---@cast dispatcher HL.Dispatcher
    hl.dispatch(dispatcher)
  end
end

---@return HL.Workspace|nil
local function active_workspace()
  local window = hl.get_active_window()
  if window ~= nil and window.workspace ~= nil then
    return window.workspace
  end

  return hl.get_active_special_workspace() or hl.get_active_workspace()
end

---@return string|nil
function M.current()
  local workspace = active_workspace()
  return workspace ~= nil and workspace.tiled_layout or nil
end

---@param name string
---@return boolean
function M.is(name)
  return M.current() == name
end

---@param specs HL.Hyprland.LayoutDispatcherSpec[]
---@return HL.Hyprland.Dispatcher
function M.by_layout(specs)
  return function()
    local current = M.current()
    if current == nil then
      return
    end

    for _, spec in ipairs(specs) do
      if spec.layout == current then
        run(spec.dispatcher)
        return
      end
    end
  end
end

---@param spec HL.Hyprland.FloatingOrLayoutDispatcherSpec
---@return HL.Hyprland.Dispatcher
function M.by_floating_or_layout(spec)
  local tiled_dispatcher = M.by_layout(spec.layouts)

  return function()
    local window = hl.get_active_window()
    if window ~= nil and window.floating == true then
      run(spec.floating)
      return
    end

    tiled_dispatcher()
  end
end

---@param step integer
---@return string|nil new_layout
---@return HL.Workspace|nil workspace
function M.cycle(step)
  local workspace = active_workspace()
  if workspace == nil or workspace.special then
    return nil
  end

  local current_index
  for index, name in ipairs(available_layouts) do
    if workspace.tiled_layout == name then
      current_index = index
      break
    end
  end

  if current_index == nil then
    return nil
  end

  local next_index = ((current_index - 1 + step) % #available_layouts) + 1
  local next_layout = available_layouts[next_index]
  hl.workspace_rule({ workspace = workspace.name, layout = next_layout })
  return next_layout, workspace
end

return M
