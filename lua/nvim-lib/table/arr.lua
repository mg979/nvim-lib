--------------------------------------------------------------------------------
-- Description: functions that only deal with arrays
-- File:        arr.lua
-- Author:      Gianmaria Bajo <mg1979.git@gmail.com>
-- License:     MIT
-- Created:     ven 24 feb 2023, 15:23:51
--------------------------------------------------------------------------------
local arr = {}
local insert = table.insert
local maxn = table.maxn

-- module metatable
local _mt = { __index = arr }

---@return table: empty table that inherits the metatable of `src`
local smt = function(src) return setmetatable({}, getmetatable(src)) end

-------------------------------------------------------------------------------
--- Iterator for all elements of an array, not only those returned by ipairs
--- (because it stops at the first nil value).
---@param t table
---@return function
function arr.npairs(t)
  local i, n = 0, maxn(t)
  return function()
    while i <= n do
      i = i + 1
      if t[i] ~= nil then
        return i, t[i]
      end
    end
  end
end

-------------------------------------------------------------------------------
--- Create an array with numeric values, with a starting value, an ending value,
--- and an increment step. If `start` > `finish`, default `step` is -1,
--- otherwise 1.
---@param start number
---@param finish number
---@param step number
---@return table
function arr.range(start, finish, step)
  local rng = setmetatable({}, _mt)
  start, finish = finish and start or 1, finish or start or 1
  step = step or (start <= finish and 1 or -1)
  for i = start, finish, step do
    insert(rng, i)
  end
  return rng
end

-------------------------------------------------------------------------------
--- Map an array in place (or to new table) with `fn`.
--- `fn` is called with (key, value) as arguments.
--- Note: this function can create holes in an array.
---@param t table
---@param fn function|string
---@param new bool|nil
---@param iter function|nil
---@return table
function arr.map(t, fn, new, iter)
  local dst = new and smt(t) or t
  for k, v in (iter or ipairs)(t) do
    dst[k] = fn(k, v)
  end
  return dst
end

-------------------------------------------------------------------------------
--- Filter an array with `fn`. Produce a new sequence.
--- `fn` is called with (key, value) as arguments.
---@param t table
---@param fn function|string
---@param iter function|nil
---@return table
function arr.filter(t, fn, iter)
  local dst = smt(t)
  for k, v in (iter or ipairs)(t) do
    if fn(k, v) then
      insert(dst, v)
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Create a new sequence from an array, by removing holes.
---@param t table
---@param iter function|nil
---@return table
function arr.seq(t, iter)
  local dst = smt(t)
  for _, v in (iter or ipairs)(t) do
    insert(dst, v)
  end
  return dst
end

-------------------------------------------------------------------------------
--- Test if a table is a sequence (array without holes).
---@see https://stackoverflow.com/a/25709704/7787852
---@param t table
---@return bool
function arr.isseq(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

-------------------------------------------------------------------------------
--- Test if a table is an array.
---@param t table
---@return bool
function arr.isarr(t)
  for k in pairs(t) do
    if type(k) ~= 'number' then
      return false
    end
  end
  return true
end

-------------------------------------------------------------------------------
--- If an array contains a value, return its index.
--- Return nil if the array doesn't contain the value.
---@param t table
---@param val any
---@param iter function|nil
---@return number|nil
function arr.indexof(t, val, iter)
  for k, v in (iter or ipairs)(t) do
    if v == val then
      return k
    end
  end
end

-------------------------------------------------------------------------------
--- Returns a copy of an array with all duplicate elements removed.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@param sort function|bool
---@param iter function|nil
---@return table
function arr.uniq(t, sort, iter)
  local seen = {}
  local dst = smt(t)
  for _, v in (iter or ipairs)(t) do
    if not seen[v] then
      table.insert(dst, v)
      seen[v] = true
    end
  end
  if sort then
    table.sort(dst, type(sort) == 'function' and sort or nil)
  end
  return dst
end

-------------------------------------------------------------------------------
--- Creates a copy of an array containing only elements from start to end.
---@param t table
---@param start number: Start range of slice
---@param finish number: End range of slice (inclusive)
---@return table: Copy of table sliced from start to finish
function arr.slice(t, start, finish)
  local dst, n, len = smt(t), 1, false
  start = start or 1
  if start == 0 or finish == 0 then
    return {}
  end
  if start < 0 then
    len = maxn(t)
    if start < -len then
      start = 1
    else
      start = len + start + 1
    end
  end
  finish = finish or len or maxn(t)
  if finish < 0 then
    len = len or maxn(t)
    if finish < -len then
      finish = 1
    else
      finish = len + finish + 1
    end
  end
  if start > finish then
    return {}
  end
  for i = start, finish do
    dst[n] = t[i]
    n = n + 1
  end
  return dst
end

-------------------------------------------------------------------------------
--- Reverse an array, in place or to a new array.
---@param t table
---@param new bool
---@return table
function arr.reverse(t, new)
  local dst = new and smt(t) or t
  local n = maxn(t)
  local i = 1
  while i < n do
    dst[i], dst[n] = t[n], t[i]
    i = i + 1
    n = n - 1
  end
  return dst
end

-------------------------------------------------------------------------------
--- Adds the values from one array to another array.
---@param dst table: Array to be extended
---@param src table: Array to extend with
---@param at number|nil: Insertion point in `dst`, or at end
---@param start number|nil: Start extending at this index of `src`
---@param finish number|nil: Stop extending at this index of `src`
---@return table
function arr.extend(dst, src, at, start, finish)
  if at then
    for i = start or 1, finish or maxn(src) do
      table.insert(dst, at, src[i])
      at = at + 1
    end
  else
    for i = start or 1, finish or maxn(src) do
      table.insert(dst, src[i])
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Flattens a hierarchy of arrays into a single sequence containing all of the
--- values.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@param iter function|nil
---@return table
function arr.flatten(t, iter)
  local dst = smt(t)

  local function _flatten(t_)
    for _, v in (iter or ipairs)(t_) do
      if type(v) == 'table' then
        _flatten(v)
      elseif v then
        insert(dst, v)
      end
    end
  end

  _flatten(t)
  return dst
end

-------------------------------------------------------------------------------
--- Set containing those elements that are in both arrays A and B.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param a table
---@param b table
---@param iter function|nil
---@return table
function arr.intersect(a, b, iter)
  local dst = smt(a)
  for _, v in (iter or ipairs)(b) do
    if arr.indexof(a, v, iter) then
      insert(dst, v)
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Set containing those elements that are in array A but not in B.
---@param a table
---@param b table
---@param iter function|nil
---@return table
function arr.subtract(a, b, iter)
  local dst = smt(a)
  for _, v in (iter or ipairs)(a) do
    if not arr.indexof(b, v, iter) then
      insert(dst, v)
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Find the maximum value in an array.
--- @param t table
--- @param min any: the minimum value to consider
--- @param iter function
--- @return any
function arr.max(t, min, iter)
  local max = min or t[1]
  for _, v in (iter or ipairs)(t) do
    if v > max then
      max = v
    end
  end
  return max
end

-------------------------------------------------------------------------------
--- Similar to table.insert, but `pos` always comes after `val`, and it returns
--- the table itself.
--- @param t table
--- @param val any
--- @param pos number
--- @return table
function arr.insert(t, val, pos)
  if pos then
    insert(t, pos, val)
  else
    insert(t, val)
  end
  return t
end

-------------------------------------------------------------------------------
--- Remove (by value) an element from an array.
--- Return a tuple with the original array, and index at which the value was
--- found, or `nil` if it wasn't found.
--- @param t table
--- @param val any
--- @return table, number|nil
function arr.remove(t, val)
  local i = arr.indexof(t, val)
  if i then
    table.remove(t, i)
    return t, i
  end
  return t, nil
end

--------------------------------------------------------------------------------
-- End of module
--------------------------------------------------------------------------------

return setmetatable(arr, {
  __call = function(_, v)
    assert(type(v) == "table", "Table required")
    return setmetatable(v, _mt)
  end
})
