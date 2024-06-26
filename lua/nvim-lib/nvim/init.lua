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
local api = require('nvim-lib').api
local nvim = {}

-------------------------------------------------------------------------------
-- Similar to the `:put` ex command, accepts a table of lines and the same
-- options as for nvim_put, plus a `reindent` option.
function nvim.put(lines, o)
  o = require('nvim-lib').tbl.merge({
    type = 'l',
    after = true,
    follow = true,
    reindent = false,
  }, o or {})
  api.put(lines, o.type, o.after, o.follow)
  -- FIXME: there are better methods for reindentation
  if o.reindent then
    vim.cmd('noautocmd normal! `[V`]=')
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
  lines = type(lines) == 'string' and vim.split(lines, '\n', { trimempty = true }) or lines
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
  api.buf_set_option(bnr, 'bufhidden', 'wipe')
  for k, v in pairs(opts or {}) do
    api.buf_set_option(bnr, k, v)
  end
  return bnr
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
  assert(type(o) == 'string' or type(o) == 'table', 'argument #1 must be string or table')
  if o2 then
    assert(
      type(o2) == 'string' or type(o2) == 'table' or type(o2) == 'boolean',
      'argument #2 must be string or table'
    )
  end
  o2 = o2 or {}
  if type(o2) == 'string' then
    o2 = { highlight = o2 }
  elseif o2 == true then
    o2 = { history = true }
  elseif o2 == false then
    o2 = { history = false }
  end
  if type(o) == 'string' then -- a single string
    o = {
      text = o,
      highlight = o2.highlight,
      history = o2.history,
    }
  elseif o[1] and type(o[1]) == 'string' then -- a list of lines
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
    chunks = { { o.text, hl } }
  elseif o.lines then
    chunks = { { table.concat(o.lines, '\n'), hl } }
  elseif o.chunks and hl then -- map chunks with a default highlight
    chunks = require('nvim-lib').tbl.map(o.chunks, function(_, v)
      return { v[1], v[2] or hl }
    end)
  end

  api.echo(chunks or o.chunks, o.history or false, o.opts or {})
end

--- Print some text with error highlight, and add it to message history.
---@param text string|table
function nvim.echoerr(text)
  nvim.echo(text, { highlight = 'Error', history = true })
end

-------------------------------------------------------------------------------
--- Ask a question, return affermative answer.
---
---@param question string
---@param answers string|table
---@return bool
function nvim.yesno(question)
  return fn.confirm(question .. '?', '&Yes\nNo') == 1
end

-------------------------------------------------------------------------------
--- Create a popup window. Default position is at cursor.
--- If `wid` is given, try to reconfigure that window, if it is still valid.
---
---@param o table: { [1] = lines, buf = n, bufopts = {}, winopts = {}, ... (options) }
---@param wid number: previous window to reconfigure
---@return number,number,table: buffer, winid, window configuration
function nvim.popup(o, wid)
  if type(o) == 'string' then
    o = { o }
  end
  local lines = o.lines or o[1] or {}
  lines = type(lines) == 'string' and vim.split(lines, '\n', { trimempty = true }) or lines
  local buf = o.buf or nvim.scratchbuf(lines, o.bufopts)
  local cfg = {
    relative = o.relative or 'cursor',
    win = o.relative == 'win' and (o.win or api.get_current_win()) or nil,
    anchor = o.anchor or 'NW',
    width = o.width or 80,
    height = o.height or #lines,
    focusable = o.enter or (o.focusable ~= nil and o.focusable),
    bufpos = o.relative == 'win' and o.bufpos or nil,
    zindex = o.zindex,
    style = o.style or 'minimal',
    border = o.border,
    noautocmd = o.noautocmd,
    title = o.title,
    title_pos = o.title_pos,
  }
  cfg.row = o.row
    or o.relative == 'win' and 0
    or o.relative == 'editor' and (vim.o.lines / 2 - cfg.height / 2)
    or 1
  cfg.col = o.col
    or o.relative == 'win' and 0
    or o.relative == 'editor' and (vim.o.columns / 2 - cfg.width / 2)
    or 1
  local win
  if wid and api.win_is_valid(wid) then
    win = wid
    api.win_set_config(win, cfg)
  else
    win = api.open_win(buf, o.enter, cfg)
  end
  if o.on_show then
    api.buf_call(buf, o.on_show)
  end
  api.win_set_option(win, 'cursorline', false)
  api.win_set_option(win, 'number', false)
  api.win_set_option(win, 'signcolumn', 'no')
  for k, v in pairs(o.winopts or {}) do
    api.win_set_option(win, k, v)
  end
  local close_on = o.close_on
                or o.enter and { "WinLeave" }
                or o.focusable and { "TabLeave" }
                or { "BufLeave", "CursorMoved", "CursorMovedI" }
  if next(close_on) then
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
  end
  for _, v in ipairs(o.mappings or {}) do
    vim.keymap.set(v[1], v[2], v[3], require("nvim-lib").tbl.merge(v[4] or {}, { buffer = buf }))
  end
  return buf, win, api.win_get_config(win)
end

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
--- a tuple:
--- • row: line number of the match (1-indexed)
--- • col: column of the match (1-indexed)
--- • match: string with the found match
--- • pat: string with the pattern used
---
---@param pat string|table
---@param flags string
---@return nil|number,number
function nvim.search(pat, flags, stopline, timeout, skip)
  flags = flags or ''
  -- magicness
  local m, nm, vnm = flags:find('m'), flags:find('M'), flags:find('V')
  local vm = not m and not nm and not vnm
  -- case sensitivity
  local i, I = flags:find('i'), flags:find('I')
  -- remove custom flags
  flags = flags:gsub('[mMViI]', '')

  if type(pat) == 'table' then
    pat = table.concat(pat, vm and '|' or '\\|')
  end

  if nm then
    pat = '\\M' .. pat
  elseif vnm then
    pat = '\\V' .. pat
  elseif vm then
    pat = '\\v' .. pat
  end

  if i then
    pat = '\\c' .. pat
  elseif I then
    pat = '\\C' .. pat
  end

  local ret = fn.searchpos(pat, flags, stopline, timeout, skip)
  if ret[1] > 0 then
    local row, col = unpack(ret)
    -- if smartcase is enabled and there are no uppercase chars in the pattern,
    -- perform case-insensitive pattern matching
    if not i and not I and not pat:find('[A-Z]') and vim.o.smartcase then
      pat = '\\c' .. pat
    end
    local str = fn.matchstr(fn.getline(ret[1]), pat, ret[2] - 1)
    return row, col, str, pat
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
  f = type(f) == 'function' and f or function()
    vim.cmd(f)
  end

  for _ = 1, cnt or 100 do
    f()
  end
  print(
    fn.matchstr(fn.reltimestr(fn.reltime(time)), '.*\\..\\{,3}')
      .. ' seconds to run '
      .. (cnt or 100)
      .. ' iterations of '
      .. (title or '')
  )
end

-------------------------------------------------------------------------------
-- End of module
-------------------------------------------------------------------------------
return nvim
