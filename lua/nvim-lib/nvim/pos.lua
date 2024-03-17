--------------------------------------------------------------------------------
-- Table to set cursor position/marks
--------------------------------------------------------------------------------
--- Position are translated to tables with named keys (buf, line, col, offset).
--- Positions as returned by vim.fn.setpos() are also supported (when setting
--- marks). The table can be called with one or two arguments:
---   Pos(position)       sets the cursor position
---   Pos(mark, position) sets the mark position

local api = vim.api
local fn = vim.fn
local log = require('nvim-lib.util').log

local _marks = {
  cursor = '.',
  lastLine = '$',
  winTopLine = 'w0',
  winBottomLine = 'w$',
  visualMode = 'v',
  visualBegin = '`<',
  visualEnd = '`>',
  yankBegin = '`[',
  yankEnd = '`]',
  lastJump = '``',
  lastPos = '`"',
  lastInsert = '`^',
  lastChange = '`.',
  sentenceBegin = '`(',
  sentenceEnd = '`)',
  paragraphBegin = '`{',
  paragraphEnd = '`}',
  visualBeginLine = "'<",
  visualEndLine = "'>",
  yankBeginLine = "'[",
  yankEndLine = "']",
  lastJumpLine = "'`",
  lastPosLine = '\'"',
  lastInsertLine = "'^",
  lastChangeLine = "'.",
  sentenceBeginLine = "'(",
  sentenceEndLine = "')",
  paragraphBeginLine = "'{",
  paragraphEndLine = "'}",
}

local function getpos(mark)
  local pos = fn.getpos(mark)
  return {
    buf = pos[1],
    line = pos[2],
    col = pos[3],
    offset = pos[4],
  }
end

local function upper(mark)
  local ok, pos = pcall(api.nvim_get_mark, _marks[mark] or mark, {})
  if not ok then
    log(pos) -- error
    return nil
  end
  if pos[1] == 0 and pos[2] == 0 and pos[3] == 0 and pos[4] == '' then
    return nil -- invalid mark
  end
  return {
    buf = pos[3],
    line = pos[1],
    col = pos[2],
    offset = 0,
  }
end

local function bufmark(mark, buf)
  local ok, pos = pcall(api.nvim_buf_get_mark, buf, _marks[mark] or mark)
  if not ok then
    log(pos) -- error
    return nil
  elseif pos[1] == 0 and pos[2] == 0 then -- invalid mark
    return nil
  end
  return { buf = buf, line = pos[1], col = pos[2], offset = 0 }
end

return setmetatable({ upper = upper, bufmark = bufmark }, {
  __metatable = false,
  __index = function(_, mark)
    return getpos(_marks[mark] or mark)
  end,
  __newindex = function(_, mark, pos)
    mark = _marks[mark] or mark
    if mark == '.' then
      if pos[1] then
        pos = getpos('.')
        fn.cursor(pos.line, pos.col)
      else
        fn.cursor(pos.line, pos.col)
      end
      return
    end
    if pos[1] and #pos == 4 then -- assume vim mark position
      fn.setpos(mark, pos)
    else
      if not pos.buf or not pos.line or not pos.col or not pos.offset then
        error('This is not a position!')
      end
      fn.setpos(mark, { pos.buf, pos.line, pos.col, pos.offset })
    end
  end,
  __call = function(_, win)
    local ok, pos = pcall(api.nvim_win_get_cursor, win or 0)
    if not ok then
      log(pos)
      return
    end
    return {
      buf = api.nvim_win_get_buf(win or 0),
      line = pos[1],
      col = pos[2],
      offset = 0,
    }
  end,
})
