--------------------------------------------------------------------------------
-- Description: functions that only deal with arrays
-- File:        arr.lua
-- Author:      Gianmaria Bajo <mg1979.git@gmail.com>
-- License:     MIT
-- Created:     ven 24 feb 2023, 15:23:51
--------------------------------------------------------------------------------
local arr = {}
local insert = table.insert

-------------------------------------------------------------------------------
--- Iterator for all elements of an array, not only those returned by ipairs
--- (because it stops at the first nil value).
---@param t table
---@return function
if jit then
  function arr.npairs(t)
    local i, n = 0, 0
    local indices = {}
    for k in pairs(t) do
      if type(k) == "number" and k > n then
        n = k
      end
    end
    return function()
      -- while i < n do
      --   i = i + 1
      --   if t[i] ~= nil then
      --     return i, t[i]
      --   end
      -- end
      i = i + 1
      if i <= n then return i, t[i] end
    end
  end
else
  function arr.npairs(t)
    local i = 0
    local n = #t
    return function()
      i = i + 1
      if i <= n then return i, t[i] end
    end
  end
end

local npairs = arr.npairs

-------------------------------------------------------------------------------
--- Map an array in place (or to new table) with `fn`.
--- `fn` is called with (key, value) as arguments.
--- Note: this function can create holes in an array.
---@param fn function
---@param t table
---@param new bool
---@return table
function arr.maparr(t, fn, new)
  local dst = new and {} or t
  for i = 1, #t do
    if t[i] ~= nil then
      dst[i] = fn(i, t[i])
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Map an array with `fn`. Produce a new sequence.
--- `fn` is called with (key, value) as arguments.
---@param fn function
---@param t table
---@return table
function arr.mapseq(t, fn)
  local dst = {}
  for k, v in npairs(t) do
    if v then
      v = fn(k, v)
      if v ~= nil then
        insert(dst, v)
      end
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Filter an array in place (or to new table) with `fn`.
--- `fn` is called with (key, value) as arguments.
--- Note: this function can create holes in an array.
---@param fn function
---@param t table
---@param new bool
---@return table
function arr.filterarr(t, fn, new)
  local dst
  if new then
    dst = {}
    for k, v in npairs(t) do
      if v and fn(k, v) then
        dst[k] = v
      end
    end
  else
    dst = t
    for k, v in npairs(t) do
      if v ~= nil and not fn(k, v) then
        dst[k] = nil
      end
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Filter an array with `fn`. Produce a new sequence.
--- `fn` is called with (key, value) as arguments.
---@param fn function
---@param t table
---@return table
function arr.filterseq(t, fn)
  local dst = {}
  for k, v in npairs(t) do
    if v ~= nil and fn(k, v) then
      insert(dst, v)
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Create a new sequence from an array, by removing holes.
---@param t table
---@return table
function arr.seq(t)
  local dst = {}
  for i = 1, #t do
    if t[i] then
      insert(dst, t[i])
    end
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
      if t[i] == nil then return false end
  end
  return true
end

-------------------------------------------------------------------------------
--- Test if a table is an array.
---@param t table
---@return bool
function arr.isarr(t)
  for k in pairs(t) do
    if type(k) ~= "number" then
      return false
    end
  end
  return true
end

-------------------------------------------------------------------------------
--- If an array contains a value, return its index.
--- Return nil if the array doesn't contain the value.
---@param t table
---@param v any
---@return number|nil
function arr.indexof(t, v)
  for k, _v in ipairs(t) do
    if _v == v then
      return k
    end
  end
end

-------------------------------------------------------------------------------
--- Returns a copy of an array with all duplicate elements removed.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@return table
function arr.uniq(t)
  local seen = { }
  local result = { }
  for _, v in npairs(t) do
    if not seen[v] then
      table.insert(result, v)
      seen[v] = true
    end
  end
  return result
end

--- Creates a copy of an array containing only elements from start to end.
---
---@param t table
---@param start number: Start range of slice
---@param finish number: End range of slice (inclusive)
---@return table: Copy of table sliced from start to finish
function arr.slice(t, start, finish)
  local dst, n = {}, 1
  for i = start or 1, finish or #t do
    dst[n] = t[i]
    n = n + 1
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
    for i = start or 1, finish or #src do
      table.insert(dst, at, src[i])
      at = at + 1
    end
  else
    for i = start or 1, finish or #src do
      table.insert(dst, src[i])
    end
  end
  return dst
end

-------------------------------------------------------------------------------
--- Flattens a hierarchy of arrays into a single array containing all of the
--- values.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param t table
---@return table
function arr.flatten(t)
  local result = {}

  local function _flatten(t_)
    for _, v in npairs(t_) do
      if type(v) == "table" then
        _flatten(v)
      elseif v then
        insert(result, v)
      end
    end
  end

  _flatten(t)
  return result
end

-------------------------------------------------------------------------------
--- Set containing those elements that are in both arrays A and B.
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---@param a table
---@param b table
---@return table
function arr.intersectarr(a, b)
  local result = {}
  for _, v in npairs(b) do
    if arr.indexof(a, v) then
      insert(result, v)
    end
  end
  return result
end

-------------------------------------------------------------------------------
--- Set containing those elements that are in array A but not in table B.
---@param a table
---@param b table
---@return table
function arr.subtractarr(a, b)
  local result = {}
  for _, v in ipairs(a) do
    if not arr.indexof(b, v) then
      insert(result, v)
    end
  end
  return result
end

return arr
