-------------------------------------------------------------------------------
--- A copy of the old metatable of {t} is made and stored inside the new
--- metatable. `__index` becomes a function that tries to get the value from the
--- old index first, then uses `tbl` or `arr` as a fallback.
--- You can also revert the injection by passing a `nil` table module.
--- Should be used in these forms:
---
--- t = setmetatable(t, mt)               -- set a metatable for a table
--- inject(tbl, t)                        -- replace metatable of `t`
--- t = inject(tbl, setmetatable(t, mt))  -- equivalent to the above lines
--- inject(nil, t)                        -- remove the injection
---
---@param tbl table: the table module to inject
---@param t table: the table to modify
---@return table: the modified table
local function inject(tbl, t)
  -- remove the hack by restoring the original __index method
  local mt = getmetatable(t)
  if not mt then
    return t
  end
  -- restore old metatable
  if not tbl then
    if not mt.__oldmt then -- no injection was made
      return t
    end
    setmetatable(t, mt.__oldmt)
    return t
  end
  -- make a copy of the old metatable, then replace the old one
  local newmt = require("nvim-lib").tbl.copy(mt)
  setmetatable(t, newmt)
  -- store the old metatable in the new one, so that it can be restored
  newmt.__oldmt = mt
  -- replace old metatable __index with one that looks also in tbl
  newmt.__index = function(tt, k)
    local base
    local oldix = newmt.__oldmt.__index
    if oldix then
      if type(oldix) == "table" then
        base = oldix[k]
      else
        base = oldix(tt, k)
      end
    end
    return base or tbl[k]
  end
  -- return table
  return t
end

return inject
