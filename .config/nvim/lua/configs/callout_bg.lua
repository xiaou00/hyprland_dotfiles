local M = {}

local ns = vim.api.nvim_create_namespace('u0_callout_bg')

local types = {
    def  = 'RenderMarkdownDef',
    thm  = 'RenderMarkdownThm',
    lem  = 'RenderMarkdownLem',
    prop = 'RenderMarkdownProp',
    col  = 'RenderMarkdownCol',
}

local function add_qed(bufnr, row)
    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
        virt_text     = { { 'Q.E.D.', 'RenderMarkdownPf' } },
        virt_text_pos = 'right_align',
        priority      = 200,
    })
end

local function apply(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local lines        = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local current_hl   = nil
    local current_type = nil
    local pf_last_row  = nil

    local function finalize_pf()
        if pf_last_row ~= nil then
            add_qed(bufnr, pf_last_row)
            pf_last_row = nil
        end
    end

    for i, line in ipairs(lines) do
        local row   = i - 1
        local ctype = line:match('^>%s*%[!(%a+)%]')

        if ctype then
            finalize_pf()
            current_type = ctype:lower()
            current_hl   = types[current_type]
        elseif not line:match('^>') then
            finalize_pf()
            current_type = nil
            current_hl   = nil
        end

        if current_type and line:match('^>') then
            if current_type == 'pf' then
                pf_last_row = row
            elseif current_hl then
                vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
                    end_row  = row + 1,
                    hl_group = current_hl,
                    hl_eol   = true,
                    priority = 9,
                })
            end
        end
    end

    finalize_pf()
end

function M.setup()
    local grp = vim.api.nvim_create_augroup('u0_callout_bg', { clear = true })
    vim.api.nvim_create_autocmd(
        { 'BufEnter', 'TextChanged', 'InsertLeave', 'BufWritePost' },
        {
            group   = grp,
            pattern = '*.md',
            callback = function(ev)
                vim.schedule(function() apply(ev.buf) end)
            end,
        }
    )
    vim.api.nvim_create_autocmd('InsertEnter', {
        group   = grp,
        pattern = '*.md',
        callback = function(ev)
            vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
        end,
    })
end

return M
