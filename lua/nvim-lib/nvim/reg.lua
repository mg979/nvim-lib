-------------------------------------------------------------------------------
--- Registers table.
---
--- Calling the table calls vim.fn.getreginfo.
--- Accessing the table yields the contents and the type.
--- Setting a value will set the type:
---   1. to "c" if the value is a string, and has no terminating "\n"
---   2. to table.regtype, if value is a table and .regtype exists
---   3. to "l" in other cases

local fn = vim.fn
local getreg, setreg = fn.getreg, fn.setreg

local _regs = {
  unnamed = function() return getreg('"') end,
  delete = function() return getreg('-') end,
  colon = function() return getreg(':') end,
  dot = function() return getreg('.') end,
  star = function() return getreg('*') end,
  plus = function() return getreg('+') end,
  file = function() return getreg('%') end,
  alt = function() return getreg('#') end,
  eval = function() return getreg('=') end,
  expr = function() return getreg('=', 1) end,
}

return setmetatable({}, {
  __metatable = false,
  __index = function(_, k) return _regs[k] and _regs[k]() or getreg(k, 1) end,
  __newindex = function(_, k, v)
    if type(v) == 'table' or v:find('\n$') then
      setreg(k, v, 'l')
    else
      setreg(k, v, 'c')
    end
  end,
  __call = function(_, k, content, t)
    if content then
      -- set register with content and type
      setreg(k, content, t)
    else
      -- return contents, type, width (if of block type)
      t = fn.getregtype(k)
      return getreg(k, 1), t:sub(1, 1), t:sub(2)
    end
  end,
})
