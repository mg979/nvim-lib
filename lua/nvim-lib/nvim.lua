-------------------------------------------------------------------------------
-- Description: functions contained in the `nvim` global variables.
-- File:        nvim.lua
-- Author:      Gianmaria Bajo <mg1979.git@gmail.com>
-- License:     MIT
-- Created:     mar 21 feb 2023, 13:09:45
-------------------------------------------------------------------------------

-- This module contains utility functions that don't have a direct
-- correspondence in the api, or that are quite different.

local fn = vim.fn
local getreg, setreg = fn.getreg, fn.setreg
local api = require("nvim-lib").api
local tbl = require("nvim-lib").tbl
local nvim = {}

-------------------------------------------------------------------------------
-- Similar to the `:put` ex command, accepts a table of lines and the same
-- options as for nvim_put, plus a `reindent` option.
function nvim.put(lines, o)
  o = tbl.merge({
    type = "l",
    after = true,
    follow = true,
    reindent = false,
  }, o or {})
  api.put(lines, o.type, o.after, o.follow)
  -- FIXME: there are better methods for reindentation
  if o.reindent then
    vim.cmd("noautocmd normal! `[V`]=")
  end
end

-------------------------------------------------------------------------------
--- Set lines for given buffer. Lines are 1-indexed. Default is:
--- 1. if nor `start` nor `finish` are given, whole buffer is replaced
--- 2. if only `start` is given, a single line is replaced
--- 3. if both are given, lines from `start` to `finish` (inclusive) are replaced
---@param buf number
---@param lines table
---@param start number
---@param finish number
function nvim.setlines(buf, lines, start, finish)
  lines = type(lines) == "string" and vim.split(lines, "\n", { trimempty = true }) or lines
  finish = (not finish and start) and start or (not finish and not start) and -1 or finish
  start = start and start - 1 or 0
  api.buf_set_lines(buf, start, finish, true, lines)
end

-------------------------------------------------------------------------------
--- Create a scratch buffer with lines, and set given buffer options.
---@param lines table
---@param opts table
---@return number
function nvim.scratchbuf(lines, opts)
  local bnr = api.create_buf(false, true)
  nvim.setlines(bnr, lines)
  if not opts then
    api.buf_set_option(bnr, "bufhidden", "wipe")
  else
    for k, v in pairs(opts or {}) do
      api.buf_set_option(bnr, k, v)
    end
  end
  return bnr
end

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
--- 3. a table with keys: rhs, mode, {opts} or any option for vim.keymap.set
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
--- The id of the augroup is the return value of the returning function.
--- Example:
---
---   local aug_id = nvim.augroup(aug_name) {
---     {
---       {"BufNewFile", "BufReadPost"},
---       command = ":UserCommandToRun"
---     },
---   }
---
---@param name string
---@return function
function nvim.augroup(name)
  local id = api.create_augroup(name, { clear = true })
  return function(autocmds)
    for _, v in ipairs(autocmds) do
      local events = v[1]
      v[1] = nil
      v.group = id
      api.create_autocmd(events, v)
    end
    return id
  end
end

-------------------------------------------------------------------------------
--- Print some text in the command line. Accepts one or two arguments.
---
--- The second argument is only considered if the first argument is either
--- a string, or is a list-like table. In this case the second argument is
--- a table with `history` and `highlight` options.
---
--- Otherwise the first argument can be a table with:
---   `text` (string): text as string
---   `lines` (table): text as table of lines
---   `chunks` (table): text as table of chunks
---   `history` (bool)
---   `highlight` (string): default highlight
---
--- When using o.lines or o.text, they will all have the same highlight.
--- Using o.chunks follows the same rules as with vim.api.echo, except that
--- default highlight (o.highlight) will be used where highlight is omitted.
---
--- Examples:
---   nvim.echo(vim.fn.system("ls"))
---   nvim.echo(vim.fn.systemlist("ls"), { highlight = "String" })
---   nvim.echo({ chunks = {{"1"}, {"2", "Error"}}, highlight = "String" })
---
---@param o table|string
function nvim.echo(o, o2)
  o2 = o2 or {}
  if type(o2) == "string" then
    o2 = { highlight = o2 }
  elseif o2 == true then
    o2 = { history = true }
  elseif o2 == false then
    o2 = { history = false }
  end
  if type(o) == "string" then -- a single string
    o = {
      text = o,
      highlight = o2.highlight,
      history = o2.history,
    }
  elseif o[1] and type(o[1]) == "string" then -- a list of lines
    o = {
      lines = o,
      highlight = o2.highlight or o.highlight,
      history = o2.history or o.history,
    }
  elseif o[1] then -- an array of chunks
    o = {
      chunks = o,
      highlight = o2.highlight or o.highlight,
      history = o2.history or o.history,
    }
  end

  local hl = o.highlight
  local chunks

  if o.text then
    chunks = {{ o.text, hl }}

  elseif o.lines then
    chunks = {{ table.concat(o.lines, "\n"), hl }}

  elseif o.chunks and hl then -- map chunks with a default highlight
    chunks = tbl.map(o.chunks, function(_, v)
      return { v[1], v[2] or hl }
    end)
  end

  api.echo(chunks or o.chunks, o.history or false, o.opts or {})
end

--- Print some text with error highlight, and add it to message history.
---@param text string|table
function nvim.echoerr(text)
  nvim.echo(text, { highlight = "Error", history = true })
end

-------------------------------------------------------------------------------
--- Ask a question, return affermative answer.
---
---@param question string
---@param answers string|table
---@return bool
function nvim.yesno(question)
  return fn.confirm(question .. "?", "&Yes\nNo") == 1
end

-------------------------------------------------------------------------------
--- Create a popup window. Default position is at cursor.
--- There are two callbacks: on_show (called when shown) and on_hide (just
--- before hiding).
---
---@param o table: { [1] = lines, buf = n, bufopts = {}, winopts = {}, ... (options) }
---@return number,number,table: buffer, winid, window configuration
function nvim.popup(o)
  if type(o) == "string" then
    o = { o }
  end
  local lines = o.lines or o[1] or {}
  lines = type(lines) == "string" and vim.split(lines, "\n", { trimempty = true }) or lines
  local buf = o.buf or nvim.scratchbuf(lines, o.bufopts)
  local win = api.open_win(buf, o.enter, {
    relative = o.relative or "cursor",
    win = o.relative == "win" and (o.win or api.get_current_win()) or nil,
    anchor = o.anchor or "NW",
    width = o.width or 80,
    height = o.height or #lines,
    col = o.col or 1,
    row = o.row or 1,
    focusable = o.enter or o.focusable,
    bufpos = o.relative == "win" and o.bufpos or nil,
    zindex = o.zindex,
    style = o.style or "minimal",
    border = o.border,
    noautocmd = o.noautocmd,
  })
  api.win_set_option(win, "cursorline", false)
  api.win_set_option(win, "number", false)
  api.win_set_option(win, "signcolumn", "no")
  for k, v in pairs(o.winopts or {}) do
    api.win_set_option(win, k, v)
  end
  if o.on_show then
    o.on_show(buf, win, api.win_get_config(win))
  end
  local close_on = o.close_on
                or o.enter and { "WinLeave" }
                or o.focusable and { "TabLeave" }
                or { "BufLeave", "CursorMoved", "CursorMovedI" }
  api.create_autocmd(close_on, {
    callback = function(_)
      if o.on_hide and api.win_is_valid(win) then
        o.on_hide()
      end
      pcall(api.win_close, win, { force = true })
      if not o.buf then
        pcall(api.buf_delete, buf, { force = true })
      end
      return true
    end,
    once = true,
  })
  return buf, win, api.win_get_config(win)
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

-- function nvim.confirm_popup(question, answers, default, kind)
--   local wh = kind == "Error" and "NormalFloat:Error,FloatBorder:Error"
--     or kind == "Info" and "NormalFloat:String,FloatBorder:String"
--     or kind == "Question" and "NormalFloat:Question,FloatBorder:Question"
--     or kind == "Warning" and "NormalFloat:WarningMsg,FloatBorder:WarningMsg" or nil
--   local lines = vim.split(question .. "\n\n", "\n")
--   table.insert(lines, ((answers or "OK"):gsub(",", "   ")))
--   nvim.popup({ lines = lines, winopts = { winhighlight = wh }, })
-- end

-------------------------------------------------------------------------------
--- pcall-ed version of vim.fn.eval. Doesn't throw the error, unless second
--- argument is `true`. This emulates a `:silent!` call.
---
---@param expr string
---@param throw bool
---@return bool,any: success, result or error message
function nvim.eval(expr, throw)
  local ok, res = pcall(vim.fn.eval, expr)
  if not ok and throw then
    error(res)
  end
  return ok, res
end

-------------------------------------------------------------------------------
--- Emulate a try/catch/finally block. Example:
---
--- nvim.try {
---   what = fn_to_test,
---
---   catch = {
---     { pat1, callback_if_pat1_matches_error -> (error) },
---     { pat2, callback_if_pat2_matches_error -> (error) },
---     { pat3, true }, -- catch it silently
---     ...
---   },
---
---   finally = callback -> (status, result, caught)
--- }
---
--- Patterns in o.catch are tried sequentially, only one can be caught.
--- If an exception isn't caught, an error will occur, but finally() block will
--- still be executed.
---
--- If an exception was caught, finally() receives as third argument a table with:
---   1. the index of the exception in the `catch` table
---   2. the result of the catch callback for that index
---
--- Return status, result of pcall.
---
---@param o table
---@return bool,any
function nvim.try(o)
  local ok, res = pcall(o.what)
  local caught
  if not ok then
    for _, catch in ipairs(o.catch) do
      if res:find(catch[1]) then
        caught = { catch[1], catch[2] == true and true or catch[2](res) }
        break
      end
    end
  end
  if o.finally then
    o.finally(ok, res, caught)
  end
  if not ok and not caught then
    error(res)
  end
  return ok, res
end

-------------------------------------------------------------------------------
--- Alternative to vim.fn.search that uses "very magic" by default, uses
--- vim.fn.searchpos, and supports some additional flags:
---   m - magic search
---   M - nomagic search
---   V - very nomagic search
---   i - case insensitive search
---   I - case sensitive search
---
--- The pattern can be a table, that will be concatenated with "\|".
--- The function returns nil if the pattern isn't found, otherwise returns
--- a tuple (row, col) (the position of the match).
---
---@param pat string|table
---@param flags string
---@return nil|number,number
function nvim.search(pat, flags, stopline, timeout, skip)
  flags = flags or ""
  -- magicness
  local m, nm, vnm = flags:find("m"), flags:find("M"), flags:find("V")
  local vm = not m and not nm and not vnm
  -- case sensitivity
  local i, I = flags:find("i"), flags:find("I")
  -- remove custom flags
  flags = flags:gsub("[mMViI]", "")

  if type(pat) == "table" then
    pat = table.concat(pat, vm and "|" or "\\|")
  end

  if nm then
    pat = "\\M" .. pat
  elseif vnm then
    pat = "\\V" .. pat
  elseif vm then
    pat = "\\v" .. pat
  end

  if i then
    pat = "\\c" .. pat
  elseif I then
    pat = "\\C" .. pat
  end

  local ret = fn.searchpos(pat, flags, stopline, timeout, skip)
  if ret[1] > 0 then
    return unpack(ret)
  end
  return nil
end

-------------------------------------------------------------------------------
--- Test the speed of a function or a vimscript command.
---@param f string
---@param cnt number
---@param title string
function nvim.testspeed(f, cnt, title)
  local time = fn.reltime()
  f = type(f) == "function" and f or function()
    vim.cmd(f)
  end

  for _ = 1, cnt or 100 do
    f()
  end
  print(
    fn.matchstr(fn.reltimestr(fn.reltime(time)), ".*\\..\\{,3}")
      .. " seconds to run " .. (cnt or 100) .. " iterations of "
      .. (title or "")
  )
end

-------------------------------------------------------------------------------
--- Registers table.
---
--- Calling the table calls vim.fn.getreginfo.
--- Accessing the table yields the contents and the type.
--- Setting a value will set the type:
---   1. to "c" if the value is a string, and has no terminating "\n"
---   2. to table.regtype, if value is a table and .regtype exists
---   3. to "l" in other cases
local _regs = {
  unnamed = function() return getreg('"') end,
  delete = function() return getreg('-') end,
  colon =  function() return getreg(':') end,
  dot =  function() return getreg('.') end,
  star =  function() return getreg('*') end,
  plus =  function() return getreg('+') end,
  file =  function() return getreg('%') end,
  alt =  function() return getreg('#') end,
  eval =  function() return getreg('=') end,
  expr =  function() return getreg('=', 1) end,
}

nvim.reg = setmetatable({}, {
  __metatable = false,
  __index = function(_, k)
    return _regs[k] and _regs[k]() or getreg(k, 1)
  end,
  __newindex = function(_, k, v)
    if type(v) == "table" or v:find("\n$") then
      setreg(k, v, "l")
    else
      setreg(k, v, "c")
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

-------------------------------------------------------------------------------
-- Keycodes as they can be used in lua scripts.
-- Keys like Esc (instead of <Esc>), CtrlO (instead of <C-o>) are also valid.
nvim.keycodes = setmetatable({}, {
  __metatable = false,
  __index = function(t,k)
    local K = k
    if k:find("^<%w+>$") then
      k = k:gsub("[<>]", "") -- lowercase k, not a mistake
    elseif k:find("^Ctrl.+") then
      K = "<C-" .. k:sub(5) .. ">"
    elseif k:find("^Shift.+") then
      K = "<S-" .. k:sub(6) .. ">"
    elseif k:find("^Meta.+") then
      K = "<M-" .. k:sub(5) .. ">"
    elseif k:find("^Alt.+") then
      K = "<A-" .. k:sub(4) .. ">"
    elseif k:find("^%w+$") then
      K = "<" .. k .. ">"
    end
    local ok, key = pcall(api.replace_termcodes, K, true, true, true)
    -- replace_termcodes returns the unchanged string if it's not a keycode
    if ok and key ~= K then
      -- set both forms (keycode/stringified)
      t[k] = key
      t[K] = key
      return key
    end
  end,
})

--------------------------------------------------------------------------------
-- Special tables that link to vim namespaces
--------------------------------------------------------------------------------

nvim.w = setmetatable({}, {
  __metatable = false,
  __index = function(_,k) return vim.w[k] end,
  __newindex = function(_,k,v) vim.w[k] = v end,
})

nvim.b = setmetatable({}, {
  __metatable = false,
  __index = function(_,k) return vim.b[k] end,
  __newindex = function(_,k,v) vim.b[k] = v end,
})

nvim.o = setmetatable({}, {
  __metatable = false,
  __index = function(_,k) return vim.o[k] end,
  __newindex = function(_,k,v) vim.o[k] = v end,
})

nvim.bo = setmetatable({}, {
  __metatable = false,
  __index = function(_,k) return vim.bo[k] end,
  __newindex = function(_,k,v) vim.bo[k] = v end,
})

nvim.wo = setmetatable({}, {
  __metatable = false,
  __index = function(_,k) return vim.wo[k] end,
  __newindex = function(_,k,v) vim.wo[k] = v end,
})

nvim.v = setmetatable({}, {
  __metatable = false,
  __index = function(_,k) return vim.v[k] end,
  __newindex = function(_,k,v) vim.v[k] = v end,
})


--------------------------------------------------------------------------------
-- Table to set cursor position/marks
--------------------------------------------------------------------------------

local _marks = {
  cursor = ".",
  eol = "$",
  winTop = "w0",
  winBottom = "w$",
  visualMode = "v",
  visualBegin = "`<",
  visualEnd = "`>",
  yankBegin = "`[",
  yankEnd = "`]",
  lastJump = "``",
  lastPos = "`\"",
  lastInsert = "`^",
  lastChange = "`.",
  sentenceBegin = "`(",
  sentenceEnd = "`)",
  paragraphBegin = "`{",
  paragraphEnd = "`}",
  visualBeginLine = "'<",
  visualEndLine = "'>",
  yankBeginLine = "'[",
  yankEndLine = "']",
  lastJumpLine = "'`",
  lastPosLine = "'\"",
  lastInsertLine = "'^",
  lastChangeLine = "'.",
  sentenceBeginLine = "'(",
  sentenceEndLine = "')",
  paragraphBeginLine = "'{",
  paragraphEndLine = "'}",
}

--- Position are translated to tables with named keys (buf, line, col, offset).
--- The table can be called with one or two arguments:
---   Pos(position)       sets the cursor position
---   Pos(mark, position) sets the mark position
nvim.pos = setmetatable({}, {
  __metatable = false,
  __index = function(_, mark)
    mark = _marks[mark] or mark
    local pos = fn.getpos(mark)
    return {
      buf = pos[1],
      line = pos[2],
      col = pos[3],
      offset = pos[4],
    }
  end,
  __newindex = function(_, mark, pos)
    mark = _marks[mark] or mark
    if pos[1] then
      fn.setpos(mark, pos)
    else
      fn.setpos(mark, { pos.buf, pos.line, pos.col, pos.offset })
    end
  end,
  __call = function(_, mark, pos)
    mark = _marks[mark] or mark
    if not pos then mark, pos = ".", mark end
    if not pos[1] then
      pos = { pos.buf, pos.line, pos.col, pos.offset }
    end
    fn.setpos(mark, pos)
  end
})

-------------------------------------------------------------------------------
-- End of module
-------------------------------------------------------------------------------
return nvim
