local M = {}

-- Language -> run command builder
local runners = {
    python     = function(f) return 'python3 '    .. vim.fn.shellescape(f) end,
    py         = function(f) return 'python3 '    .. vim.fn.shellescape(f) end,
    lua        = function(f) return 'lua '         .. vim.fn.shellescape(f) end,
    sh         = function(f) return 'bash '        .. vim.fn.shellescape(f) end,
    bash       = function(f) return 'bash '        .. vim.fn.shellescape(f) end,
    zsh        = function(f) return 'zsh '         .. vim.fn.shellescape(f) end,
    javascript = function(f) return 'node '        .. vim.fn.shellescape(f) end,
    js         = function(f) return 'node '        .. vim.fn.shellescape(f) end,
    typescript = function(f) return 'npx ts-node ' .. vim.fn.shellescape(f) end,
    ts         = function(f) return 'npx ts-node ' .. vim.fn.shellescape(f) end,
    ruby       = function(f) return 'ruby '        .. vim.fn.shellescape(f) end,
    rb         = function(f) return 'ruby '        .. vim.fn.shellescape(f) end,
    go         = function(f) return 'go run '      .. vim.fn.shellescape(f) end,
    cpp        = function(f)
        local out = vim.fn.tempname()
        return 'g++ ' .. vim.fn.shellescape(f) .. ' -o ' .. out .. ' && ' .. out
    end,
    c          = function(f)
        local out = vim.fn.tempname()
        return 'gcc ' .. vim.fn.shellescape(f) .. ' -o ' .. out .. ' && ' .. out
    end,
    rust       = function(f)
        local out   = vim.fn.tempname()
        local rustc = vim.fn.exepath('rustc')
        if rustc == '' then rustc = vim.fn.expand('~/.cargo/bin/rustc') end
        return vim.fn.shellescape(rustc) .. ' ' .. vim.fn.shellescape(f) .. ' -o ' .. out .. ' && ' .. out
    end,
    sage       = function(f) return 'sage '        .. vim.fn.shellescape(f) end,
}

local extensions = {
    python = '.py',  py = '.py',
    lua    = '.lua',
    sh     = '.sh',  bash = '.sh', zsh = '.zsh',
    javascript = '.js', js = '.js',
    typescript = '.ts', ts = '.ts',
    ruby   = '.rb',  rb = '.rb',
    go     = '.go',
    rust   = '.rs',
    cpp    = '.cpp',
    c      = '.c',
    sage   = '.sage',
}

function M.run_codeblock()
    local buf     = vim.api.nvim_get_current_buf()
    local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed
    local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    -- 1. scan upward from cursor to find opening ```
    local start_row, lang = nil, ''
    for i = cur_row, 0, -1 do
        local m = lines[i + 1]:match('^```(%w*)')
        if m ~= nil then
            start_row = i
            lang = m:lower()
            break
        end
    end

    if not start_row then
        vim.notify('Cursor is not inside a code block', vim.log.levels.WARN)
        return
    end

    -- 2. scan downward to find closing ```
    local end_row = nil
    for i = start_row + 1, #lines - 1 do
        if lines[i + 1]:match('^```%s*$') then
            end_row = i
            break
        end
    end

    if not end_row then
        vim.notify('Code block is not closed', vim.log.levels.WARN)
        return
    end

    -- 3. extract code lines (between the fences)
    local code_lines = {}
    for i = start_row + 1, end_row - 1 do
        table.insert(code_lines, lines[i + 1])
    end

    if #code_lines == 0 then
        vim.notify('Code block is empty', vim.log.levels.WARN)
        return
    end

    local runner = runners[lang]
    if not runner then
        local name = lang ~= '' and lang or '(unknown)'
        vim.notify('No runner for language: ' .. name, vim.log.levels.WARN)
        return
    end

    -- 4. write to a temp file
    local ext     = extensions[lang] or '.txt'
    local tmpfile = vim.fn.tempname() .. ext
    vim.fn.writefile(code_lines, tmpfile)
    local cmd = runner(tmpfile)

    -- 5. calculate float window position (just below the closing fence)
    local cur_win    = vim.api.nvim_get_current_win()
    local win_height = vim.api.nvim_win_get_height(cur_win)
    local win_width  = vim.api.nvim_win_get_width(cur_win)
    local first_line = vim.fn.line('w0') - 1  -- 0-indexed first visible line

    local float_height = 10
    local float_width  = math.min(72, math.floor(win_width * 0.7))
    local float_col    = math.floor((win_width - float_width) / 2)  -- horizontally centered

    local float_row = end_row - first_line + 1  -- one line below closing ```
    if float_row + float_height >= win_height - 1 then
        -- not enough room below; shift up
        float_row = math.max(0, win_height - float_height - 1)
    end

    -- 6. open the floating buffer and window
    local float_buf = vim.api.nvim_create_buf(false, true)
    local float_win = vim.api.nvim_open_win(float_buf, true, {
        relative  = 'win',
        win       = cur_win,
        row       = float_row,
        col       = float_col,
        width     = float_width,
        height    = float_height,
        style     = 'minimal',
        border    = 'none',
        focusable = true,
        zindex    = 50,
    })

    -- 7. run in a terminal
    vim.fn.termopen(cmd, {
        env = { TERM = 'xterm-256color' },
        on_exit = function(_, _, _)
            vim.fn.delete(tmpfile)
        end,
    })

    -- press q to close
    vim.keymap.set('n', 'q', function()
        pcall(vim.api.nvim_win_close, float_win, true)
    end, { buffer = float_buf, noremap = true, silent = true })

    vim.cmd('startinsert')
end

return M
