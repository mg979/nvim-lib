local M = {}

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
