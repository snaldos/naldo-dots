-- Shared construction of shell-safe command strings.

local M = {}

---@param value any
---@return string
function M.quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param ... any
---@return string
function M.command(...)
  local arguments = {}
  for _, argument in ipairs({ ... }) do
    table.insert(arguments, M.quote(argument))
  end

  return table.concat(arguments, " ")
end

return M
