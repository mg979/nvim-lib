local nvim = require("nvim-lib").nvim

-- Table with all plugins configurations, as set by users
local configs = {}

-- Table with all plugins setup functions, as set by plugins
local setups = {}

local function set_options(_, plugin)
  return function(opts)
    configs[plugin] = opts
    if setups[plugin] then
      setups[plugin](opts)
    end
  end
end

local function print_setups()
  local text = "The following plugins have been configured:\n\n"
  for name, cfg in pairs(configs) do
    text = text .. name .. " = " .. vim.inspect(cfg) .. "\n\n"
  end
  nvim.popup({ text, enter = true, border = "rounded" })
end

return setmetatable({}, {
  __index = set_options,
  __newindex = function()
    error("Access to this table is protected.")
  end,
  __call = function()
    return {
      get = function(k)
        return configs[k]
      end,
      set = function(k, v)
        if type(v) ~= "function" then
          error("Setup must be a function, accepting an options table as argument.")
        end
        setups[k] = v
      end,
      info = print_setups,
    }
  end,
})
