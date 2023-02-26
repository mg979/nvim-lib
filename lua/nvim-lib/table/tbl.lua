local tbl = {}
local insert = table.insert

-------------------------------------------------------------------------------
--- Enumerate a table sorted by its keys.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param a table
---@param comp function|nil
---@return function
function tbl.spairs(t, comp)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do
    insert(keys, k)
  end
  table.sort(keys, comp)

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

-------------------------------------------------------------------------------
--- Map a table in place (or to new table) with fn.
--- The function is called with (key, value) as arguments.
--- The default iterator is `pairs`, but it can be overridden with the `iter`
--- argument. Other useful iterators: `ipairs`, `arr.npairs`.
--- Note: this function can create holes in an array.
---@param t table
---@param fn function
---@param new bool|nil
---@param iter function|nil
---@return table
function tbl.map(t, fn, new, iter)
  local dst = new and {} or t
  for k, v in (iter or pairs)(t) do
    dst[k] = fn(k, v)
  end
  return dst
end

-------------------------------------------------------------------------------
--- Filter a table in place (or to new table) with fn.
--- The default iterator is `pairs`, but it can be overridden with the `iter`
--- argument. Other useful iterators: `ipairs`, `arr.npairs`.
--- The function is called with (key, value) as arguments.
--- Note: this function can create holes in an array.
---@param t table
---@param fn function
---@param new bool|nil
---@param iter function|nil
---@return table
function tbl.filter(t, fn, new, iter)
  local dst
  if new then
    dst = {}
    for k, v in (iter or pairs)(t) do
      if fn(k, v) then
        dst[k] = v
      end
    end
  else
    dst = t
    for k, v in (iter or pairs)(t) do
      if not fn(k, v) then
        dst[k] = nil
      end
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Create a new array-like table from the values of t.
---@param t table
---@param fn function
---@return table
function tbl.toarray(t)
  local dst = {}
  for _, v in pairs(t) do
    insert(dst, v)
  end
  return dst
end

-------------------------------------------------------------------------------
--- Merge two tables, with the second one overwriting the first one, unless
--- "keep" is true, in which case values that are present already in t1 are
--- kept. If "keep" is "error", trying to overwrite a key is an error.
--- Both tables can be nil.
---@param t1 table|nil
---@param t2 table|nil
---@param keep bool|string
---@return table
function tbl.merge(t1, t2, keep)
  local err = keep == "error"
  if t2 then
    t1 = t1 or {}
    if keep then
      for k, v in pairs(t2) do
        if t1[k] == nil then
          t1[k] = v
        elseif err then
          error("tbl.merge: key exists in table")
        end
      end
    else
      for k, v in pairs(t2) do
        t1[k] = v
      end
    end
  end
  return t1 or {}
end

-------------------------------------------------------------------------------
--- Test if table is empty.
---@param t table
---@return bool
function tbl.empty(t)
  return next(t) == nil
end

-------------------------------------------------------------------------------
--- Returns true if the table contains the specified value.
---@param t table
---@param value any
---@return bool
function tbl.contains(t, value)
  for _, v in pairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------
--- Make a shallow copy of a table. Copies metatable if `meta` is true.
---@param t table
---@param meta bool|nil
---@param iter function|nil
---@return table
function tbl.copy(t, meta, iter)
  local dst = {}
  for k, v in (iter or pairs)(t) do
    dst[k] = v
  end
  if meta ~= false then
    local mt = getmetatable(t)
    if mt then
      setmetatable(dst, mt)
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Get the value of a nested key inside a table.
---@param t table: table to traverse
---@param ... string: name of nested keys to look for in the table
---@return any: the nested value
function tbl.get(t, ...)
  for _, k in ipairs({...}) do
    if type(t) == "table" then
      if not t[k] then
        return nil
      end
      t = t[k]
    else
      return nil
    end
  end
  return t
end

-------------------------------------------------------------------------------
--- Counts the number of non-nil values in table `t`.
---@see https://github.com/Tieske/Penlight/blob/master/lua/pl/tablex.lua
---@param t table
---@return number
function tbl.count(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-------------------------------------------------------------------------------
--- Replace all instances of `value` with `replacement` in an table.
---@param value
---@param replacement
---@param iter function|nil
function tbl.replace(t, val, rep, iter)
  for k, v in (iter or pairs)(t) do
    if v == val then
      t[k] = rep
    end
  end
end

-------------------------------------------------------------------------------
--- Return an array with all keys used in a table.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@return table
function tbl.keys(t)
  local keys = {}
  for k in pairs(t) do
    insert(keys, k)
  end
  return keys
end

-------------------------------------------------------------------------------
--- Return an array with all values used in a table.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@return table
function tbl.values(t)
  local values = {}
  for _, v in pairs(t) do
    insert(values, v)
  end
  return values
end

-------------------------------------------------------------------------------
--- Make a complete copy of a table, including any child tables it contains.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@return table
function tbl.deepcopy(t)
  -- keep track of already seen objects to avoid loops
  local seen = {}

  local function _copy(obj)
    if type(obj) ~= "table" then
      return obj
    elseif seen[obj] then
      return seen[obj]
    end

    local clone = {}
    seen[obj] = clone
    for key, value in pairs(obj) do
      clone[key] = _copy(value)
    end

    setmetatable(clone, getmetatable(obj))
    return clone
  end

  return _copy(t)
end

-------------------------------------------------------------------------------
--- Compares two tables.
---@param a table
---@param b table
---@return bool
function tbl.equal(a, b, deep)
  local compared = {}
  for k, v in pairs(a) do
    if not b[k] then
      return false
    elseif b[k] ~= v then
      if not deep
        or type(b[k]) ~= "table"
        or type(v) ~= "table"
        or not tbl.equal(b[k], v, true)
      then
        return false
      end
    end
    compared[k] = true
  end
  for k in pairs(b) do
    if not compared[k] then
      -- it means this key wasn't in `a`
      return false
    end
  end
  return true
end

-------------------------------------------------------------------------------
--- Set containing those elements that are in both tables A and B.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param a table
---@param b table
---@param iter function|nil
---@return table
function tbl.intersect(a, b, iter)
  local result = {}
  for k, v in (iter or pairs)(b) do
    if a[k] then
      result[k] = v
    end
  end
  return result
end

-------------------------------------------------------------------------------
--- Set containing those elements that are in table A but not in table B.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param a table
---@param b table
---@param iter function|nil
---@return table
function tbl.difference(a, b, iter)
  local result = {}
  for k, v in (iter or pairs)(a) do
    if not b[k] then
      result[k] = v
    end
  end
  return result
end

return tbl
