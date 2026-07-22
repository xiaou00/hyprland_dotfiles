require "nvchad.autocmds"
require("configs.latex_preview").setup()
require("configs.callout_bg").setup()

-- Auto-save: trigger every few seconds via CursorHold
vim.opt.updatetime = 2000

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "CursorHold" }, {
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! write")
        end
    end,
})

-- Auto-continue blockquote on Enter in markdown
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function()
        vim.keymap.set('i', '<CR>', function()
            local line = vim.api.nvim_get_current_line()
            if line:match('^>') then
                local prefix = line:match('^(>+%s*)')
                return '<CR>' .. prefix
            end
            return '<CR>'
        end, { expr = true, buffer = true, silent = true })
    end,
})

-- Re-apply dark mode every time the nvdash (dashboard) renders
vim.api.nvim_create_autocmd("User", {
    pattern = "NvDashReady",
    callback = function()
        vim.schedule(function()
            require("theme_toggle").init()
        end)
    end,
})

-- Re-apply when nvim-tree buffer opens (nvim-tree resets its highlights on open)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "NvimTree",
    callback = function()
        vim.schedule(function()
            require("theme_toggle").init()
        end)
    end,
})

-- Re-apply dark mode on VimEnter (catches startup before LazyDone)
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.schedule(function()
            require("theme_toggle").init()
        end)
    end,
})

-- Re-apply after all lazy plugins finish loading (fixes highlights overridden by plugin setup)
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = function()
        vim.schedule(function()
            require("theme_toggle").init()
        end)
    end,
})
