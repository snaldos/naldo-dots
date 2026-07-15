local layout = require("hyprland.lib.layout")
local vars = require("hyprland.variables")

-- Monitor fallback; generated monitor-specific settings are loaded separately.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})

-- Input, appearance, and built-in layouts.
hl.config({
  input = {
    kb_layout = "gb",
    numlock_by_default = true,
    repeat_delay = 250,
    repeat_rate = 35,
    follow_mouse = 1,

    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      clickfinger_behavior = true,
      scroll_factor = 0.8,
      tap_to_click = false,
    },
  },

  general = {
    no_focus_fallback = true,
    layout = "scrolling",
    gaps_in = 5,
    gaps_out = 10,
    border_size = 1,
  },

  binds = {
    window_direction_monitor_fallback = false,
  },

  decoration = {
    rounding = 20,
    rounding_power = 2,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 0xee1a1a1a,
    },

    -- Noctalia-recommended blur.
    blur = {
      enabled = true,
      size = 3,
      passes = 2,
      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = true,
  },

  scrolling = {
    column_width = 0.5,
    fullscreen_on_one_column = false,
    focus_fit_method = 1, -- Fit the focused column into view rather than centering it.
    follow_focus = true,
    direction = vars.scrolling.direction,
  },

  group = {
    groupbar = {
      enabled = false,
    },
  },
})

-- Workspace animation.
hl.curve("workspace_smooth", {
  type = "bezier",
  points = { { 0.16, 1 }, { 0.3, 1 } },
})

hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 14,
  bezier = "workspace_smooth",
  style = "slidevert",
})

-- Gestures.
hl.gesture({
  fingers = 3,
  direction = "left",
  action = function()
    if layout.is("scrolling") then
      hl.dispatch(hl.dsp.layout("move " .. vars.scrolling.move_col.left))
    end
  end,
})

hl.gesture({
  fingers = 3,
  direction = "right",
  action = function()
    if layout.is("scrolling") then
      hl.dispatch(hl.dsp.layout("move " .. vars.scrolling.move_col.right))
    end
  end,
})

hl.gesture({
  fingers = 4,
  direction = "horizontal",
  action = "workspace",
})
