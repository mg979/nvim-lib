local fn = vim.fn
local M = {}

local function locals()
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

local function upvalues(f)
  local variables = {}
  local idx = 1
  while true do
    local ln, lv = debug.getupvalue(f, idx)
    if ln ~= nil then
      variables[ln] = lv
    else
      break
    end
    idx = 1 + idx
  end
  return variables
end

local function get_local_env(f)
  local variables = upvalues(f)
  for k, v in pairs(locals()) do
    variables[k] = v
  end
  return variables
end

-------------------------------------------------------------------------------
--- Make a function from a string. The function accepts two arguments, that will
--- be replaced by the current key and the value of the processed table.
---@param string string
---@return function
function M.kvfunc(string)
  local caller
  for i = 4, 1, -1 do
    caller = debug.getinfo(i, "f")
    if caller and caller.func then
      caller = caller.func
      break
    elseif i == 1 then
      error("nvim-lib: Error in resolving function environment.")
    end
  end
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

--------------------------------------------------------------------------------
-- Error log
--------------------------------------------------------------------------------
local logs = {}

function M.log(err)
  if not err then
    if #logs > 0 then
      for _, e in ipairs(logs) do
        print(string.format("%s: %s", e[1], e[2]))
      end
    else
      print("No errors")
    end
    return
  end
  table.insert(logs, { fn.strftime("%y/%m/%d %H:%M"), err })
end

return M
