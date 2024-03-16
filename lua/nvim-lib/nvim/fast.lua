--------------------------------------------------------------------------------
-- Functions that could be called already at startup
-- Put in a separate module so that startup isn't slowed down too much.
--------------------------------------------------------------------------------

local fn = vim.fn
local api = require("nvim-lib").api
local tbl = require("nvim-lib").tbl
local nvim = {}

-------------------------------------------------------------------------------
--- Create any number of user commands from a table, where the keys are the
--- commands names, value[1]|value.cmd is the callback(fn|string), the rest are
--- options. Example:
---
---   nvim.commands {
---
---     UserCommandName = {
---       cmd = lua_callback,
---       nargs = 1,
---       complete = complete_func,
---       desc = "Command description here.",
---     },
---
---     AnotherUserCommandName = {...},
---
---   }
---
---@param cmds table
function nvim.commands(cmds)
  for name, cmd in pairs(cmds) do
    local f = cmd[1] or cmd.cmd or cmd.command
    cmd[1], cmd.cmd, cmd.command = nil, nil, nil
    api.create_user_command(name, f, cmd)
  end
end

-------------------------------------------------------------------------------
--- Set any number of mappings with vim.keymap.set.
--- Each key of the table is a `lhs` for a mapping. Its value can be:
--- 1. a string: a vim command for the `rhs`, with default options
--- 2. a function: the `rhs`, with default options
--- 3. a table with keys: `rhs`, `mode`, `opts` or any option for vim.keymap.set
---@param maps table
function nvim.mappings(maps)
  for lhs, map in pairs(maps) do
    if type(map) ~= "table" then
      map = { rhs = map }
    end
    map.opts = map.opts or tbl.copy(map)
    map.opts[1], map.opts.rhs, map.opts.mode = nil, nil, nil
    vim.keymap.set(map.mode or 'n', lhs, map.rhs or map[1], map.opts)
  end
end

-------------------------------------------------------------------------------
--- Create an augroup, to be filled with autocommands to be declared in the
--- returning function. The autocommands belong to the defined augroup.
--- The returning function has 2 return values:
---   • the augroup id
---   • an array with the autocommands ids
---
--- Example:
---
---   local aug_id, au_ids = nvim.augroup(aug_name) {
---     {
---       {"BufNewFile", "BufReadPost"},
---       command = ":UserCommandToRun"
---     },
---   }
---
---@param name string
---@param clear bool|nil
---@return function
function nvim.augroup(name, clear)
  clear = clear == nil and true or clear
  local id, ids = api.create_augroup(name, { clear = clear }), {}
  return function(autocmds)
    for _, v in ipairs(autocmds) do
      local events = v[1]
      v[1] = nil
      v.group = id
      table.insert(ids, api.create_autocmd(events, v))
    end
    return id, ids
  end
end

-------------------------------------------------------------------------------
--- Return size in bytes of buffer.
---
--- In vimscript (for current buffer only) it would be:
---   line2byte(line('$') + 1) - 1
---
---@param buf number
---@return number
function nvim.bufsize(buf)
  return api.buf_get_offset(buf or 0, api.buf_line_count(buf or 0))
end

-------------------------------------------------------------------------------
--- Return the path of the script from where the function is called.
function nvim.scriptname()
  return debug.getinfo(2).source:match('@?(.*)')
end





--------------------------------------------------------------------------------
-- End of module
--------------------------------------------------------------------------------

return nvim
