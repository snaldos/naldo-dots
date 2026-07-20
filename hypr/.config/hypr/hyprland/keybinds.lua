local layout = require("hyprland.lib.layout")
local shell = require("hyprland.lib.shell")
local vars = require("hyprland.variables")

local main_mod = vars.main_mod

local function bind(keys, dispatcher, options)
  options = options or {}
  if options.submap_universal == nil then
    options.submap_universal = true
  end

  return hl.bind(keys, dispatcher, options)
end

local function noctalia_command(...)
  return shell.command(vars.noctalia.executable, vars.noctalia.ipc_subcommand, ...)
end

local function workspace_in_group(position)
  local workspace = hl.get_active_workspace()
  if workspace == nil then
    return position
  end

  return math.floor((workspace.id - 1) / vars.workspace_group_size) * vars.workspace_group_size + position
end

local function resize_window_by_percent(x_percent, y_percent)
  return function()
    local monitor = hl.get_active_monitor()
    if monitor == nil then
      return
    end

    hl.dispatch(hl.dsp.window.resize({
      x = monitor.width * x_percent / 100,
      y = monitor.height * y_percent / 100,
      relative = true,
      window = "active",
    }))
  end
end

local function scrolling_toggle_maximized_or_promote()
  local window = hl.get_active_window()
  local monitor = hl.get_active_monitor()
  if window == nil or monitor == nil or type(window.size) ~= "table" then
    return
  end

  local window_width = window.size.x
  if type(window_width) ~= "number" or monitor.width <= 0 then
    return
  end

  if window_width >= monitor.width * 0.9 then
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
    hl.dispatch(hl.dsp.layout("promote"))
  else
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))
  end
end

local function focus_window_or_workspace(dispatcher, workspace_fallback)
  if workspace_fallback == nil then
    return dispatcher
  end

  return function()
    local window = hl.get_active_window()
    hl.dispatch(dispatcher)

    if hl.get_active_window() == window then
      hl.dispatch(hl.dsp.focus({ workspace = workspace_fallback }))
    end
  end
end

local function window_move_signature(window)
  if window == nil then
    return nil
  end

  local at = window.at
  local size = window.size
  local layout_state = window.layout
  at = type(at) == "table" and at or {}
  size = type(size) == "table" and size or {}
  layout_state = type(layout_state) == "table" and layout_state or {}

  local workspace = window.workspace
  local monitor = window.monitor
  local column = type(layout_state.column) == "table" and layout_state.column or {}
  local group = window.group

  return table.concat({
    tostring(at.x),
    tostring(at.y),
    tostring(size.x),
    tostring(size.y),
    tostring(workspace and workspace.id),
    tostring(monitor and monitor.id),
    tostring(column.index),
    tostring(layout_state.index_in_column),
    tostring(group and group.current_index),
  }, "|")
end

local function move_window_or_workspace(dispatcher, workspace_fallback)
  if workspace_fallback == nil then
    return dispatcher
  end

  return function()
    local window = hl.get_active_window()
    if window == nil then
      return
    end

    local before = window_move_signature(window)
    local result = hl.dispatch(dispatcher)
    if type(result) == "table" and result.ok == false then
      return
    end

    if window_move_signature(window) == before then
      hl.dispatch(hl.dsp.window.move({
        workspace = workspace_fallback,
        follow = true,
        window = window,
      }))
    end
  end
end

local function when_layout(name, dispatcher)
  return layout.by_layout({
    { layout = name, dispatcher = dispatcher },
  })
end

local function scrolling_dispatch(message)
  return when_layout("scrolling", hl.dsp.layout(message))
end

-- Noctalia and media.
bind(main_mod .. " + Space", hl.dsp.exec_cmd(noctalia_command("panel-toggle", "launcher")), {
  description = "Noctalia: Toggle launcher",
})
bind(main_mod .. " + O", hl.dsp.exec_cmd(noctalia_command("panel-toggle", "control-center")), {
  description = "Noctalia: Toggle control center",
})
bind(main_mod .. " + I", hl.dsp.exec_cmd(noctalia_command("settings-toggle")), {
  description = "Noctalia: Toggle settings",
})
bind(main_mod .. " + SHIFT + Space", hl.dsp.exec_cmd(noctalia_command("panel-toggle", "clipboard")), {
  description = "Noctalia: Toggle clipboard",
})
bind(main_mod .. " + B", hl.dsp.exec_cmd(noctalia_command("bar-toggle")), {
  description = "Noctalia: Toggle bar",
})

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctalia_command("volume-up")), {
  description = "Audio: Raise volume",
})
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctalia_command("volume-down")), {
  description = "Audio: Lower volume",
})
bind("XF86AudioMute", hl.dsp.exec_cmd(noctalia_command("volume-mute")), {
  description = "Audio: Toggle mute",
})
bind("XF86AudioMicMute", hl.dsp.exec_cmd(noctalia_command("mic-mute")), {
  description = "Audio: Toggle microphone mute",
})
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(noctalia_command("brightness-up")), {
  description = "Brightness: Increase",
})
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctalia_command("brightness-down")), {
  description = "Brightness: Decrease",
})

bind("Print", hl.dsp.exec_cmd(noctalia_command("screenshot-fullscreen")), {
  description = "Screenshot: Fullscreen",
})
bind("SHIFT + Print", hl.dsp.exec_cmd(noctalia_command("screenshot-region")), {
  description = "Screenshot: Region",
})

-- Applications.
bind(main_mod .. " + Return", hl.dsp.exec_cmd(vars.terminal.command), { description = "App: Terminal" })
bind(main_mod .. " + E", hl.dsp.exec_cmd(vars.file_manager), { description = "App: File manager" })

-- Numbered workspaces.
local total_workspaces = vars.workspace_group_size * #vars.workspace_monitors
if total_workspaces <= 9 then
  for workspace = 1, total_workspaces do
    bind(main_mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }), {
      description = "Workspace: Focus " .. workspace,
    })
    bind(main_mod .. " + ALT + " .. workspace, hl.dsp.window.move({ workspace = workspace, follow = false }), {
      description = "Window: Send to workspace " .. workspace,
    })
  end
else
  for position = 1, vars.workspace_group_size do
    local key = position == 10 and 0 or position

    bind(main_mod .. " + " .. key, function()
      hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(position) }))
    end, { description = "Workspace: Focus " .. position })

    bind(main_mod .. " + ALT + " .. key, function()
      hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(position), follow = false }))
    end, { description = "Window: Send to workspace " .. position })
  end
end

bind(main_mod .. " + SHIFT + mouse_up", hl.dsp.focus({ workspace = "r+1" }), {
  description = "Workspace: Focus next",
})
bind(main_mod .. " + SHIFT + mouse_down", hl.dsp.focus({ workspace = "r-1" }), {
  description = "Workspace: Focus previous",
})

-- Special workspaces.
bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"), {
  description = "Workspace: Toggle scratchpad",
})
bind(main_mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), {
  description = "Window: Send to scratchpad",
})
bind(main_mod .. " + N", hl.dsp.workspace.toggle_special("notepad"), {
  description = "Workspace: Toggle notepad",
})
bind(main_mod .. " + ALT + N", hl.dsp.window.move({ workspace = "special:notepad", follow = false }), {
  description = "Window: Send to notepad",
})

-- Core window actions.
bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Window: Move" })
bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Window: Resize" })
bind(main_mod .. " + Q", hl.dsp.window.close(), { description = "Window: Close" })
bind(main_mod .. " + T", hl.dsp.window.float(), { description = "Window: Float/Tile" })
bind(
  main_mod .. " + C",
  layout.by_floating_or_layout({
    floating = hl.dsp.window.center(),
    layouts = {
      {
        layout = "scrolling",
        dispatcher = hl.dsp.exec_cmd(shell.command(vars.scripts.center_scrolling_active)),
      },
    },
  }),
  { description = "Window: Center floating / center scrolling active" }
)
bind(
  main_mod .. " + F",
  layout.by_layout({
    {
      layout = "dwindle",
      dispatcher = hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    },
    {
      layout = "scrolling",
      dispatcher = scrolling_toggle_maximized_or_promote,
    },
  }),
  { description = "Window: Fullscreen" }
)
bind(main_mod .. " + P", hl.dsp.window.pin(), { description = "Window: Pin" })

-- Directional window management.
local float_move_step = 40
local resize_step = 5
local directional_binds = {
  { key = "H", direction = "left", x = -float_move_step, y = 0, resize_x = -resize_step, resize_y = 0 },
  {
    key = "J",
    direction = "down",
    workspace_fallback = "r+1",
    x = 0,
    y = float_move_step,
    resize_x = 0,
    resize_y = resize_step,
  },
  {
    key = "K",
    direction = "up",
    workspace_fallback = "r-1",
    x = 0,
    y = -float_move_step,
    resize_x = 0,
    resize_y = -resize_step,
  },
  { key = "L", direction = "right", x = float_move_step, y = 0, resize_x = resize_step, resize_y = 0 },
}

local scrolling_focus_direction = {
  left = "l",
  right = "r",
  up = "u",
  down = "d",
}

for _, spec in ipairs(directional_binds) do
  local focus_description = "Layout-Position: Focus window " .. spec.direction
  if spec.workspace_fallback ~= nil then
    focus_description = focus_description .. " / Workspace: Focus " .. spec.workspace_fallback .. " at edge"
  end

  local scrolling_resize
  if spec.resize_x ~= 0 then
    scrolling_resize = hl.dsp.layout("colresize " .. (spec.resize_x > 0 and "+conf" or "-conf"))
  else
    scrolling_resize = resize_window_by_percent(0, spec.resize_y)
  end

  local scrolling_swap
  if spec.direction == "left" or spec.direction == "right" then
    scrolling_swap = hl.dsp.layout("swapcol " .. vars.scrolling.swap_col[spec.direction])
  else
    scrolling_swap = hl.dsp.window.swap({ direction = spec.direction })
  end

  bind(
    main_mod .. " + " .. spec.key,
    layout.by_floating_or_layout({
      floating = hl.dsp.window.move({ x = spec.x, y = spec.y, relative = true }),
      layouts = {
        {
          layout = "dwindle",
          dispatcher = focus_window_or_workspace(hl.dsp.focus({ direction = spec.direction }), spec.workspace_fallback),
        },
        {
          layout = "scrolling",
          dispatcher = focus_window_or_workspace(
            hl.dsp.layout("focus " .. scrolling_focus_direction[spec.direction]),
            spec.workspace_fallback
          ),
        },
      },
    }),
    { repeating = true, description = focus_description .. " / Floating: Move " .. spec.direction }
  )

  bind(
    main_mod .. " + SHIFT + " .. spec.key,
    layout.by_floating_or_layout({
      floating = resize_window_by_percent(spec.resize_x, spec.resize_y),
      layouts = {
        { layout = "dwindle", dispatcher = resize_window_by_percent(spec.resize_x, spec.resize_y) },
        { layout = "scrolling", dispatcher = scrolling_resize },
      },
    }),
    { repeating = true, description = "Layout-Size: Resize window " .. spec.direction }
  )

  local move_description = "Layout-Position: Move window " .. spec.direction
  local move_dispatcher = hl.dsp.window.move({ direction = spec.direction })
  if spec.workspace_fallback ~= nil then
    move_description = move_description .. " / Workspace: Move with window to " .. spec.workspace_fallback .. " at edge"
    move_dispatcher = move_window_or_workspace(move_dispatcher, spec.workspace_fallback)
  else
    move_description = move_description .. " inside monitor"
  end

  bind(main_mod .. " + ALT + " .. spec.key, move_dispatcher, {
    description = move_description,
  })

  bind(
    main_mod .. " + CTRL + " .. spec.key,
    layout.by_layout({
      { layout = "dwindle", dispatcher = hl.dsp.window.swap({ direction = spec.direction }) },
      { layout = "scrolling", dispatcher = scrolling_swap },
    }),
    { description = "Layout-Position: Swap window " .. spec.direction }
  )
end

bind(
  main_mod .. " + Tab",
  layout.by_floating_or_layout({
    floating = hl.dsp.window.cycle_next({ tiled = true }),
    layouts = {
      { layout = "dwindle", dispatcher = hl.dsp.window.cycle_next({ floating = true }) },
      { layout = "scrolling", dispatcher = hl.dsp.window.cycle_next({ floating = true }) },
    },
  }),
  { description = "Window: Toggle focus between tiled/floating" }
)
bind(
  main_mod .. " + SHIFT + Tab",
  layout.by_floating_or_layout({
    floating = hl.dsp.window.cycle_next({ floating = true }),
    layouts = {
      { layout = "dwindle", dispatcher = hl.dsp.window.cycle_next({ tiled = true }) },
      { layout = "scrolling", dispatcher = hl.dsp.window.cycle_next({ tiled = true }) },
    },
  }),
  { description = "Window: Cycle within current mode" }
)

-- Layout switching and layout-specific actions.
bind(
  main_mod .. " + Slash",
  hl.dsp.exec_cmd(shell.command(vars.scripts.layout_selector, vars.noctalia.executable, vars.noctalia.ipc_subcommand)),
  { description = "Layout-Management: Select layout" }
)

bind(main_mod .. " + R", when_layout("dwindle", hl.dsp.layout("togglesplit")), {
  description = "Dwindle: Toggle split",
})

bind(main_mod .. " + CTRL + Period", scrolling_dispatch("colresize +0.25"), {
  description = "Scrolling: Fine width increase",
})
bind(main_mod .. " + CTRL + Comma", scrolling_dispatch("colresize -0.25"), {
  description = "Scrolling: Fine width decrease",
})
bind(
  main_mod .. " + SHIFT + Period",
  scrolling_dispatch("consume_or_expel " .. vars.scrolling.consume_or_expel.right),
  { description = "Scrolling: Send to right column" }
)
bind(
  main_mod .. " + SHIFT + Comma",
  scrolling_dispatch("consume_or_expel " .. vars.scrolling.consume_or_expel.left),
  { description = "Scrolling: Send to left column" }
)
bind(main_mod .. " + Period", scrolling_dispatch("move " .. vars.scrolling.move_col.prev), {
  description = "Scrolling: Move up",
})
bind(main_mod .. " + Comma", scrolling_dispatch("move " .. vars.scrolling.move_col.next), {
  description = "Scrolling: Move down",
})
bind(main_mod .. " + CTRL + mouse_up", scrolling_dispatch("move " .. vars.scrolling.move_col.prev), {
  description = "Scrolling: Move up",
})
bind(main_mod .. " + CTRL + mouse_down", scrolling_dispatch("move " .. vars.scrolling.move_col.next), {
  description = "Scrolling: Move down",
})

-- Groups.
bind(main_mod .. " + W", hl.dsp.group.toggle(), { description = "Group: Toggle group" })
bind(main_mod .. " + BracketLeft", hl.dsp.group.prev(), { description = "Group: Previous group" })
bind(main_mod .. " + BracketRight", hl.dsp.group.next(), { description = "Group: Next group" })

-- Monitors.
local monitor_directions = {
  { key = "Left", direction = "l", label = "left" },
  { key = "Down", direction = "d", label = "down" },
  { key = "Up", direction = "u", label = "up" },
  { key = "Right", direction = "r", label = "right" },
}

for _, spec in ipairs(monitor_directions) do
  bind(main_mod .. " + " .. spec.key, hl.dsp.focus({ monitor = spec.direction }), {
    description = "Monitors: Focus monitor " .. spec.label,
  })
  bind(main_mod .. " + ALT + " .. spec.key, hl.dsp.window.move({ monitor = spec.direction }), {
    description = "Monitors: Send window to monitor " .. spec.label,
  })
end

-- Menus.
bind(
  main_mod .. " + X",
  hl.dsp.exec_cmd(shell.command(vars.scripts.scripts_launcher, vars.terminal.executable, vars.terminal.float_app_id)),
  { description = "Menus: Open scripts launcher" }
)
bind(main_mod .. " + Backslash", hl.dsp.exec_cmd(shell.command(vars.scripts.theme_launcher)), {
  description = "Menus: Open theme launcher",
})
bind(
  main_mod .. " + Z",
  hl.dsp.exec_cmd(
    shell.command(
      vars.scripts.app_launcher,
      vars.terminal.executable,
      vars.terminal.float_app_id,
      vars.window.centered_floating_size
    )
  ),
  { description = "Menus: Open app launcher" }
)

-- Utilities.
bind(
  "CTRL + Print",
  hl.dsp.exec_cmd(shell.command(vars.scripts.annotated_snip, vars.noctalia.executable, vars.noctalia.ipc_subcommand)),
  { description = "Utilities: Annotated screen snip" }
)
bind(
  "ALT + Print",
  hl.dsp.exec_cmd(shell.command(vars.scripts.snip_to_search, vars.noctalia.executable, vars.noctalia.ipc_subcommand)),
  { description = "Utilities: Google Lens" }
)

-- Pointer controls.
bind(main_mod .. " + Equal", hl.dsp.exec_cmd([[/usr/bin/printf 'wheel 1\n' | /usr/bin/dotoolc]]), {
  repeating = true,
  description = "Pointer: Scroll up",
})

bind(main_mod .. " + Minus", hl.dsp.exec_cmd([[/usr/bin/printf 'wheel -1\n' | /usr/bin/dotoolc]]), {
  repeating = true,
  description = "Pointer: Scroll down",
})
