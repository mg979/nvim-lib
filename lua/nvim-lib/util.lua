local M = {}

local function locals(fn)
  local variables = {}
  local idx = 1
  while true do
    local ln, lv = debug.getlocal(5, idx)
    if ln ~= nil then
      variables[ln] = lv
    else
      break
    end
    idx = 1 + idx
  end
  return variables
end

local function upvalues(fn)
  local variables = {}
  local idx = 1
  while true do
    local ln, lv = debug.getupvalue(fn, idx)
    if ln ~= nil then
      variables[ln] = lv
    else
      break
    end
    idx = 1 + idx
  end
  return variables
end

local function get_local_env(fn)
  local variables = locals(fn)
  for k, v in pairs(upvalues(fn)) do
    variables[k] = v
  end
  return variables
end

-------------------------------------------------------------------------------
--- Make a function from a string. The function accepts two arguments, that will
--- be replaced by the current key and the value of the processed table.
---@param string string
---@return function
function M.kvfunc(string, caller)
  local func = load("return function(_K, _V) return " .. string .. " end")()
  setfenv(func, get_local_env(caller))
  return func
end

-------------------------------------------------------------------------------
--- Get length of array (part of table with numerical indices).
--- #t is unreliable.
---@see https://www.lua.org/manual/5.1/manual.html#2.5.5
---@param t table
---@return number
function M.length(t)
  local n = 0
  for k in pairs(t) do
    if type(k) == "number" and k > n then
      n = k
    end
  end
  return n
end

return M
