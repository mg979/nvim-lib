local arr = require('nvim-lib').arr
local fn = vim.fn

local chars = {
  hor = '─',
  vert = '│',
  topleft = '╭',
  topright = '╮',
  botleft = '╰',
  botright = '╯',
}

local cow = [[
       o
        o   ^__^
         o  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
]]

local function draw_box(lines, tip)
  local longest_line = arr.max(arr.map(lines, function(_, v) return fn.strwidth(v) end, true))
  local hor = string.rep(chars.hor, longest_line + 2)
  local top = chars.topleft .. hor .. chars.topright
  local bot = chars.botleft .. hor .. chars.botright

  if tip then
    top = top:sub(1, 6) .. ' Tip ' .. top:sub(22)
  end

  local box = { top }
  for _, v in ipairs(lines) do
    local off = longest_line - fn.strwidth(v)
    table.insert(box, string.format('%s %s%s %s', chars.vert, v, string.rep(' ', off), chars.vert))
  end
  table.insert(box, bot)
  return box
end

local function quote(boxed, tip, startify)
  math.randomseed(os.time())
  local pool
  if tip then
    pool = require('nvim-lib.fortune.tips')
  elseif startify or math.random(2) == 1 then
    pool = require('nvim-lib.fortune.startify')
  else
    pool = require('nvim-lib.fortune.quotes')
  end
  local wrapped = {}
  for _, v in ipairs(pool[math.random(#pool)]) do
    table.insert(wrapped, fn.split(v, '\\%50c.\\{-}\\zs\\s', 1))
  end
  return boxed and draw_box(arr.flatten(wrapped), tip) or arr.flatten(wrapped)
end

local default = {
  cow = true,
  boxed = true,
  as_string = false,
  is_tip = false,
  startify = false,
  pad_top = 1,
  pad_bottom = false,
}

return function(opts)
  opts = opts or {}
  for k, v in pairs(default) do
    if opts[k] == nil then
      opts[k] = v
    end
  end
  local q = quote(opts.boxed, opts.is_tip, opts.startify)
  if opts.as_string then
    local pre = opts.pad_top and string.rep('\n', opts.pad_top) or ''
    local post = opts.pad_bottom and string.rep('\n', opts.pad_bottom) or ''
    return pre .. table.concat(q, '\n') .. (opts.cow and ('\n' .. cow) or '') .. post
  else
    if opts.pad_top then
      for _ = 1, opts.pad_top do
        table.insert(q, 1, '\n')
      end
    end
    if opts.pad_bottom then
      for _ = 1, opts.pad_bottom do
        table.insert(q, '\n')
      end
    end
    if opts.cow then
      return arr.extend(q, { '', vim.split(cow, '\n') })
    else
      return q
    end
  end
end
