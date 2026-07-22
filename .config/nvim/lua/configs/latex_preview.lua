local M = {}

local DISPLAY_ENVS = {
  'equation', 'equation*', 'align', 'align*',
  'gather',   'gather*',   'multline', 'multline*',
  'eqnarray', 'eqnarray*', 'alignat',  'alignat*',
  'flalign',  'flalign*',  'split',    'array',
}

-- ── Macro collection ─────────────────────────────────────────────────────────

local function next_brace_group(str, pos)
  local s = str:find('{', pos, true)
  if not s then return nil end
  local depth, i = 1, s + 1
  while i <= #str do
    local c = str:sub(i, i)
    if     c == '\\' then i = i + 2
    elseif c == '{'  then depth = depth + 1; i = i + 1
    elseif c == '}'  then
      depth = depth - 1
      if depth == 0 then return s, i, str:sub(s + 1, i - 1) end
      i = i + 1
    else i = i + 1 end
  end
end

local function parse_newcommands(text)
  local macros = {}
  local pos = 1
  while pos <= #text do
    local ms, me = text:find('\\[re]*newcommand%s*', pos)
    local ds, de = text:find('\\DeclareMathOperator%s*', pos)
    if ds and (not ms or ds < ms) then ms, me = ds, de end
    if not ms then break end
    local p = me + 1
    local name
    if text:sub(p, p) == '{' then
      local _, e, n = text:find('^{(\\[%a@]+)}', p)
      if e then name = n; p = e + 1 end
    else
      local _, e, n = text:find('^(\\[%a@]+)', p)
      if e then name = n; p = e + 1 end
    end
    if name then
      local nargs = 0
      local os, oe, ns2 = text:find('^%s*%[(%d+)%]', p)
      if os then nargs = tonumber(ns2); p = oe + 1 end
      local od = text:find('^%s*%[', p)
      if od then
        local depth, i = 1, od + 1
        while i <= #text and depth > 0 do
          local c = text:sub(i, i)
          if c == '[' then depth = depth + 1 elseif c == ']' then depth = depth - 1 end
          i = i + 1
        end
        p = i
      end
      local def_s = text:find('^%s*{', p)
      if def_s then
        local _, def_e, def = next_brace_group(text, def_s)
        if def then macros[name] = { nargs = nargs, def = def }; p = def_e + 1 end
      end
    end
    pos = ms + 1
  end
  return macros
end

local function collect_project_macros(path, visited)
  visited = visited or {}
  if visited[path] then return {} end
  visited[path] = true
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return {} end
  local text = table.concat(lines, '\n')
  local macros = parse_newcommands(text)
  local dir = vim.fn.fnamemodify(path, ':h')
  for _, pat in ipairs({ '\\input%s*{([^}]+)}', '\\include%s*{([^}]+)}' }) do
    for inc in text:gmatch(pat) do
      local inc_path = dir .. '/' .. inc
      if not inc_path:match('%.tex$') then inc_path = inc_path .. '.tex' end
      local sub = collect_project_macros(inc_path, visited)
      for k, v in pairs(sub) do if not macros[k] then macros[k] = v end end
    end
  end
  return macros
end

local function find_project_root(bufnr)
  local ok, vt = pcall(vim.api.nvim_buf_get_var, bufnr, 'vimtex')
  if ok and vt and vt.tex and vt.tex ~= '' then return vt.tex end
  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  local dir = vim.fn.fnamemodify(buf_path, ':h')
  for _, f in ipairs(vim.fn.glob(dir .. '/*.tex', false, true)) do
    local c = table.concat(vim.fn.readfile(f), '\n')
    if c:match('\\documentclass') then return f end
  end
  return buf_path
end

local macro_cache = {}
local function get_macros(bufnr)
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local cached = macro_cache[bufnr]
  if cached and cached.tick == tick then return cached.macros end
  local macros = collect_project_macros(find_project_root(bufnr))
  macro_cache[bufnr] = { tick = tick, macros = macros }
  return macros
end

-- ── Macro expansion ───────────────────────────────────────────────────────────

local function expand_macros(str, macros)
  for _ = 1, 20 do
    local changed = false
    for cmd, macro in pairs(macros) do
      local pat     = vim.pesc(cmd) .. '([^%a@])'
      local pat_end = vim.pesc(cmd) .. '$'
      if macro.nargs == 0 then
        local new = str:gsub(pat, macro.def .. '%1'):gsub(pat_end, macro.def)
        if new ~= str then str = new; changed = true end
      else
        local result, last, search = {}, 1, 1
        while search <= #str do
          local ms = str:find(vim.pesc(cmd), search, false)
          if not ms then break end
          local after = ms + #cmd
          if str:sub(after, after):match('[%a@]') then
            search = ms + 1
          else
            local args, p, ok2 = {}, after, true
            while str:sub(p, p):match('%s') do p = p + 1 end
            for _ = 1, macro.nargs do
              local gs, ge, content = next_brace_group(str, p)
              if gs then args[#args+1] = content; p = ge + 1
              else ok2 = false; break end
            end
            if ok2 then
              local sub = macro.def
              for ai, arg in ipairs(args) do sub = sub:gsub('#'..ai, arg) end
              result[#result+1] = str:sub(last, ms-1)
              result[#result+1] = sub
              last = p; search = p; changed = true
            else
              search = ms + 1
            end
          end
        end
        if changed then result[#result+1] = str:sub(last); str = table.concat(result) end
      end
    end
    if not changed then break end
  end
  return str
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

-- utftex first, latex2text fallback for both modes
local function render(math_str, macros, mode)
  if vim.trim(math_str) == '' then return '' end
  -- Collapse all whitespace (including newlines) to single spaces so utftex
  -- never sees a bare newline inside \begin{pmatrix}...\end{pmatrix}, which
  -- caused the first matrix row to appear shifted ("向前倾").
  local expanded = vim.trim(expand_macros(math_str, macros):gsub('%s+', ' '))
  local input = (mode == 'inline') and ('$' .. expanded .. '$') or expanded
  local out = vim.fn.system({ 'utftex' }, input)
  if vim.v.shell_error ~= 0 or vim.trim(out) == '' then
    out = vim.fn.system({ 'latex2text' }, input)
  end
  local cleaned_out = out:gsub("^[\r\n]+", ""):gsub("[\r\n]+$", "")
  return cleaned_out
end

-- ── Math detection at cursor ──────────────────────────────────────────────────

-- Find \[ that is NOT part of \\[...] (LaTeX line-break-with-spacing).
local function find_open(line, pos)
  pos = pos or 1
  while pos <= #line do
    local p = line:find('%\\%[', pos)
    if not p then return nil end
    if p == 1 or line:sub(p - 1, p - 1) ~= '\\' then return p end
    pos = p + 1
  end
end

-- Find \] that is NOT part of \\]
local function find_close(line, pos)
  pos = pos or 1
  while pos <= #line do
    local p = line:find('%\\%]', pos)
    if not p then return nil end
    if p == 1 or line:sub(p - 1, p - 1) ~= '\\' then return p end
    pos = p + 1
  end
end

-- Find math environment containing (row, col) (both 0-indexed).
-- Returns math_str, mode or nil.
local function find_math_at_pos(lines, row, col)
  local line = lines[row + 1]
  if not line then return nil end

  -- Single-line: $$...$$
  local s = 1
  while true do
    local ms, me, math = line:find('%$%$(.-)%$%$', s)
    if not ms then break end
    if ms-1 <= col and col < me then return math, 'display' end
    s = me + 1
  end
  -- Single-line: $...$
  local masked = line:gsub('%$%$(.-)%$%$', function(m) return string.rep('\0', #m+4) end)
  s = 1
  while true do
    local ms, me, math = masked:find('%$([^%$\n]+)%$', s)
    if not ms then break end
    if ms-1 <= col and col < me then return line:sub(ms+1, me-1), 'inline' end
    s = me + 1
  end
  -- Single-line: \(...\)
  s = 1
  while true do
    local ms, me, math = line:find('%\\%((.-)%\\%)', s)
    if not ms then break end
    if ms-1 <= col and col < me then return math, 'inline' end
    s = me + 1
  end
  -- Single-line: \[...\]  (guard against \\[...])
  s = 1
  while true do
    local op = find_open(line, s)
    if not op then break end
    local cp = find_close(line, op + 2)
    if not cp then break end
    if op-1 <= col and col < cp+1 then
      return line:sub(op + 2, cp - 1), 'display'
    end
    s = cp + 1
  end

  -- Multi-line \[...\]: scan back for \[, forward for \]
  for i = row + 1, math.max(1, row - 100), -1 do
    local l = lines[i]
    if not l then break end
    if find_close(l) and i ~= row + 1 then break end  -- past a closer
    local bp = find_open(l)
    if bp then
      local math_lines = {}
      local after = l:sub(bp + 2)
      if vim.trim(after) ~= '' then math_lines[#math_lines+1] = after end
      local end_row = nil
      for j = i + 1, math.min(#lines, i + 200) do
        local lj = lines[j]
        local ep = find_close(lj)
        if ep then
          local before = lj:sub(1, ep - 1)
          if vim.trim(before) ~= '' then math_lines[#math_lines+1] = before end
          end_row = j
          break
        end
        math_lines[#math_lines+1] = lj
      end
      if end_row and (row+1) >= i and (row+1) <= end_row then
        return table.concat(math_lines, '\n'), 'display'
      end
      break
    end
  end

  -- Multi-line environments
  for _, env in ipairs(DISPLAY_ENVS) do
    local begin_pat = '%\\begin%{' .. vim.pesc(env) .. '%}'
    local end_pat   = '%\\end%{'   .. vim.pesc(env) .. '%}'
    for i = row + 1, math.max(1, row - 200), -1 do
      local l = lines[i]
      if not l then break end
      if l:match(end_pat) and i ~= row + 1 then break end
      if l:match(begin_pat) then
        local math_lines = {}
        local after_begin = l:match(begin_pat .. '(.*)') or ''
        if vim.trim(after_begin) ~= '' then math_lines[#math_lines+1] = after_begin end
        local end_row = nil
        for j = i + 1, math.min(#lines, i + 200) do
          local lj = lines[j]
          if lj:match(end_pat) then
            local before = lj:match('^(.-)' .. end_pat) or ''
            if vim.trim(before) ~= '' then math_lines[#math_lines+1] = before end
            end_row = j
            break
          end
          math_lines[#math_lines+1] = lj
        end
        if end_row and (row+1) >= i and (row+1) <= end_row then
          return table.concat(math_lines, '\n'), 'display'
        end
        break
      end
    end
  end

  return nil
end

-- ── Float window management ───────────────────────────────────────────────────

local auto_win  = nil   -- handle of the auto-preview window
local auto_math = nil   -- math string currently shown

local function close_auto()
  if auto_win and vim.api.nvim_win_is_valid(auto_win) then
    vim.api.nvim_win_close(auto_win, true)
  end
  auto_win  = nil
  auto_math = nil
end

local function open_auto(rendered)
  close_auto()
  local rlines = vim.split(rendered, '\n')
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rlines)
  vim.bo[buf].modifiable = false
  local width = 10
  for _, l in ipairs(rlines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  auto_win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor', row = 1, col = 0,
    width    = math.min(width + 2, vim.o.columns - 4),
    height   = math.min(#rlines, 20),
    style    = 'minimal', border = 'none',
  })
end

-- Called on CursorHold: show/update auto-preview if in math.
function M.auto_preview()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos   = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local math_str, mode = find_math_at_pos(lines, row, col)

  if not math_str then close_auto(); return end
  if math_str == auto_math and auto_win and vim.api.nvim_win_is_valid(auto_win) then return end

  local macros  = get_macros(bufnr)
  local rendered = render(math_str, macros, mode)
  if rendered == '' then close_auto(); return end

  auto_math = math_str
  open_auto(rendered)
end

-- Manual float for cursor position (n mode) or visual selection (v mode).
local function show_manual_float(math_str, macros, mode)
  local rendered = render(math_str, macros, mode)
  if rendered == '' then
    vim.notify('[LaTeX] Rendering failed', vim.log.levels.WARN); return
  end
  local rlines = vim.split(rendered, '\n')
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rlines)
  vim.bo[buf].modifiable = false
  local width = 10
  for _, l in ipairs(rlines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor', row = 1, col = 0,
    width    = math.min(width + 2, vim.o.columns - 4),
    height   = math.min(#rlines, 20),
    style    = 'minimal', border = 'none',
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end,
  })
end

function M.float_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos   = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local math_str, mode = find_math_at_pos(lines, row, col)
  if not math_str then
    vim.notify('[LaTeX] No math expression at cursor', vim.log.levels.WARN); return
  end
  show_manual_float(math_str, get_macros(bufnr), mode)
end

function M.float_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(bufnr, s[2]-1, e[2], false)
  if #lines == 0 then vim.notify('[LaTeX] Empty selection', vim.log.levels.WARN); return end
  lines[#lines] = lines[#lines]:sub(1, e[3])
  lines[1]      = lines[1]:sub(s[3])
  local sel = table.concat(lines, '\n')
  local math_str, mode
  local inner = sel:match('^%$%$(.-)%$%$$') or sel:match('^%$(.-)%$$')
  if inner then
    math_str, mode = inner, 'inline'
  else
    inner = sel:match('^%\\%[(.-)%\\%]$')
    if inner then math_str, mode = inner, 'display'
    else
      mode = (sel:match('\\begin{') or sel:match('\\\\')) and 'display' or 'inline'
      math_str = sel
    end
  end
  show_manual_float(math_str, get_macros(bufnr), mode)
end

-- Debug: dump extracted math to a scratch buffer (:LaTeXDebug)
function M.debug_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos   = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local math_str, mode = find_math_at_pos(lines, row, col)
  if not math_str then
    vim.notify('[LaTeX] No math at cursor', vim.log.levels.WARN); return
  end
  local macros  = get_macros(bufnr)
  local expanded = expand_macros(math_str, macros)
  local dump = {
    '=== raw extracted ===',
    math_str,
    '',
    '=== after macro expansion ===',
    expanded,
    '',
    '=== mode: ' .. (mode or '?') .. ' ===',
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(dump, '\n'), '\n'))
  vim.cmd('vsplit')
  vim.api.nvim_win_set_buf(0, buf)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup()
  -- HTML: highlight $$...$$ and $...$ with the same math color as LaTeX
  vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern  = '*.html',
    callback = function()
      if vim.w.html_math_hl then return end
      vim.fn.matchadd('@markup.math', '\\$\\$\\_.\\{-}\\$\\$', 12)
      vim.fn.matchadd('@markup.math', '\\$[^$\\n]\\{-}[^$\\n]\\$', 10)
      vim.w.html_math_hl = true
    end,
  })

  vim.api.nvim_create_autocmd('CursorHold', {
    pattern  = { '*.tex', '*.html' },
    callback = function() vim.schedule(M.auto_preview) end,
  })
  -- Close auto-preview immediately when cursor moves
  vim.api.nvim_create_autocmd('CursorMoved', {
    pattern  = { '*.tex', '*.html' },
    callback = close_auto,
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern  = { 'tex', 'html' },
    callback = function()
      local buf  = vim.api.nvim_get_current_buf()
      local opts = { buffer = buf, silent = true }
      vim.api.nvim_buf_create_user_command(buf, 'LaTeXDebug',
        function() M.debug_at_cursor() end, { desc = 'LaTeX: dump extracted math' })
      vim.keymap.set('n', '<leader>lk', M.float_at_cursor,
        vim.tbl_extend('force', opts, { desc = 'LaTeX: float preview at cursor' }))
      vim.keymap.set('v', '<leader>lk', function()
        vim.cmd('normal! \x1b')
        M.float_selection()
      end, vim.tbl_extend('force', opts, { desc = 'LaTeX: float preview of selection' }))
    end,
  })
end

return M
