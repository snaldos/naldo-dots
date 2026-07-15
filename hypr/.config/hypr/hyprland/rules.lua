local vars = require("hyprland.variables")

local bitwarden_title_pattern = "^Extension: %(Bitwarden Password Manager%) %- Bitwarden .+ Zen Browser$"
local bitwarden_center_delay_ms = 450

---@param value string
---@return string
local function escape_regex(value)
  local escaped = value:gsub("([%.%+%*%?%^%$%(%)%[%]%{%}%|\\])", "\\%1")
  return escaped
end

---@param values string[]
---@return string
local function exact_regex(values)
  local escaped = {}
  for _, value in ipairs(values) do
    table.insert(escaped, escape_regex(value))
  end

  return ("^(%s)$"):format(table.concat(escaped, "|"))
end

-- Static window rules.
local window_rules = {
  {
    name = "default-no-blur",
    match = { class = ".*" },
    no_blur = true,
  },
  {
    name = "blur",
    match = { class = exact_regex({ vars.terminal.app_id, vars.terminal.float_app_id }) },
    no_blur = false,
  },
  {
    name = "zen-browser-theme",
    match = { class = exact_regex({ "zen" }) },
    opacity = "1 1",
    no_blur = true,
  },
  {
    name = "centered-floating-apps",
    match = {
      class = exact_regex({
        vars.terminal.float_app_id,
        "dev.noctalia.Noctalia",
        "com.gabm.satty",
      }),
    },
    float = true,
    size = vars.window.centered_floating_size,
    center = true,
  },
}

for _, rule in ipairs(window_rules) do
  hl.window_rule(rule)
end

-- Zen changes extension popup titles after mapping, so this cannot be a static initial rule.
local function configure_bitwarden_popup(window)
  if window == nil or window.class ~= "zen" or window.title == nil then
    return
  end

  if window.title:match(bitwarden_title_pattern) == nil then
    return
  end

  hl.dispatch(hl.dsp.window.float({
    window = window,
    action = "set",
  }))

  hl.timer(function()
    if window.mapped ~= true then
      return
    end

    hl.dispatch(hl.dsp.window.center({ window = window }))
  end, {
    timeout = bitwarden_center_delay_ms,
    type = "oneshot",
  })
end

hl.on("window.title", configure_bitwarden_popup)

for _, window in ipairs(hl.get_windows({ mapped = true })) do
  configure_bitwarden_popup(window)
end

-- Special workspaces always use scrolling.
local special_workspace_rules = {
  { workspace = "name:special:scratchpad", gaps_out = 30 },
  { workspace = "name:special:notepad", gaps_out = 60 },
}

for _, rule in ipairs(special_workspace_rules) do
  hl.workspace_rule({
    workspace = rule.workspace,
    gaps_out = rule.gaps_out,
    layout = "scrolling",
    layout_opts = { direction = vars.scrolling.direction },
  })
end

-- Persistent numbered workspaces for Noctalia indicators.
for monitor_index, monitor in ipairs(vars.workspace_monitors) do
  for workspace_in_group = 1, vars.workspace_group_size do
    local workspace = (monitor_index - 1) * vars.workspace_group_size + workspace_in_group
    hl.workspace_rule({
      workspace = tostring(workspace),
      monitor = monitor,
      persistent = true,
    })
  end
end

-- Noctalia layer rules from its Hyprland integration documentation.
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
  },
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
