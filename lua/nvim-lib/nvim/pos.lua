--------------------------------------------------------------------------------
-- Table to set cursor position/marks
--------------------------------------------------------------------------------
--- Position are translated to tables with named keys (buf, line, col, offset).
--- Positions as returned by vim.fn.setpos() are also supported (when setting
--- marks). The table can be called with one or two arguments:
---   Pos(position)       sets the cursor position
---   Pos(mark, position) sets the mark position

local fn = vim.fn

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

return setmetatable({}, {
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
