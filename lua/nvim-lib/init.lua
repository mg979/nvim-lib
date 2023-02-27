--------------------------------------------------------------------------------
-- Description: nvim api... gosh
-- File:        api.lua
-- Author:      Gianmaria Bajo <mg1979.git@gmail.com>
-- License:     MIT
-- Created:     lun 20 feb 2023, 18:21:41
--------------------------------------------------------------------------------

--  ╭───────────────────────────╮
--  │ Proxies for api functions │
--  ╰───────────────────────────╯
local api = setmetatable({}, {
  __index = function(t, k)
    local v = vim.api["nvim_" .. k]
    t[k] = v
    return v
  end,
})

--  ╭───────────────────────╮
--  │ New functions, tables │
--  ╰───────────────────────╯
local nvim = setmetatable({}, {
  __index = function(t, k)
    local v
    local sub = {
      reg = true,
      keycodes = true,
      pos = true,
    }
    if sub[k] then
      v = require("nvim-lib.nvim." .. k)
    else
      v = require("nvim-lib.nvim.fast")[k]
      if not v then
        v = require("nvim-lib.nvim")[k]
      end
    end
    t[k] = v
    return v
  end
})

--  ╭─────────────────╮
--  │ Table functions │
--  ╰─────────────────╯
local tbl = setmetatable({}, {
  __index = function(t, k)
    local v = require("nvim-lib.table.tbl")[k]
    t[k] = v
    return v
  end
})

local arr = setmetatable({}, {
  __index = function(t, k)
    local v = require("nvim-lib.table.arr")[k]
    t[k] = v
    return v
  end
})

-------------------------------------------------------------------------------
---Require individual modules, or call the table to have them all.
return setmetatable({
  api = api,
  nvim = nvim,
  tbl = tbl,
  arr = arr,
}, {
  __call = function()
    return api, nvim, tbl, arr
  end,
})
