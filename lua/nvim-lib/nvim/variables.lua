--------------------------------------------------------------------------------
-- Special tables that link to vim namespaces
--------------------------------------------------------------------------------

return {
  w = setmetatable({}, {
    __metatable = false,
    __index = function(_,k) return vim.w[k] end,
    __newindex = function(_,k,v) vim.w[k] = v end,
  }),

  b = setmetatable({}, {
    __metatable = false,
    __index = function(_,k) return vim.b[k] end,
    __newindex = function(_,k,v) vim.b[k] = v end,
  }),

  o = setmetatable({}, {
    __metatable = false,
    __index = function(_,k) return vim.o[k] end,
    __newindex = function(_,k,v) vim.o[k] = v end,
  }),

  bo = setmetatable({}, {
    __metatable = false,
    __index = function(_,k) return vim.bo[k] end,
    __newindex = function(_,k,v) vim.bo[k] = v end,
  }),

  wo = setmetatable({}, {
    __metatable = false,
    __index = function(_,k) return vim.wo[k] end,
    __newindex = function(_,k,v) vim.wo[k] = v end,
  }),

  v = setmetatable({}, {
    __metatable = false,
    __index = function(_,k) return vim.v[k] end,
    __newindex = function(_,k,v) vim.v[k] = v end,
  }),
}
