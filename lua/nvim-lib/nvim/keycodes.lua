-------------------------------------------------------------------------------
-- Keycodes as they can be used in lua scripts.
-- Keys like Esc (instead of <Esc>), CtrlO (instead of <C-o>) are also valid.
return setmetatable({}, {
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
    local ok, key = pcall(vim.api.nvim_replace_termcodes, K, true, true, true)
    -- replace_termcodes returns the unchanged string if it's not a keycode
    if ok and key ~= K then
      -- set both forms (keycode/stringified)
      t[k] = key
      t[K] = key
      return key
    end
  end,
})
