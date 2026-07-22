require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- 常见的 Ctrl mapping
map("n", "<C-a>", "ggVG", { desc = "Select All" })
map("i", "<C-a>", "<ESC>ggVGi", { desc = "Select All" })
map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-z>", "<ESC>ui", { desc = "Undo" })
map("i", "<C-r>", "<ESC><C-r>i", { desc = "Redo" })
map("i", "<C-s>", "<ESC>v", { desc = "Select" })
map("n", "<C-s>", "v", { desc = "Select" })
map("i", "<C-d>", "<ESC>Vdi", { desc = "Delete line" })
map("i", "<C-BS>", "<ESC>\"_diwi", { desc = "Delete word" })
map("i", "<C-del>", "<ESC>\"_daB", { desc = "Delete content between brackets" })

-- 注释
map("i", "<C-/>", "<Esc>gccA", { desc = "Comment line and append" })
map("n", "<C-/>", "gcc", { desc = "Toggle comment" })
map("v", "<C-/>", "gc", { desc = "Toggle comment selection" })

-- Copilot
map("i", "<C-]>", "copilot#Suggest()", { expr = true, desc = "Trigger Copilot suggestion" })
map("n", "<leader>ct", function()
    if vim.g.copilot_enabled == 1 then
        vim.g.copilot_enabled = 0
        print("Copilot Off")
    else
        vim.g.copilot_enabled = 1
        print("Copilot On")
    end
end, { desc = "Toggle Copilot" })

-- Auto-save toggle
local autosave_enabled = true
map('n', '<leader>as', function()
    autosave_enabled = not autosave_enabled
    if autosave_enabled then
        vim.opt.updatetime = 2000
        print("Auto-save On")
    else
        vim.opt.updatetime = 4000
        print("Auto-save Off")
    end
end, { desc = 'Toggle Auto-save' })

-- Toggle line wrap
map('n', '<leader>w', function()
    vim.opt.wrap = not vim.opt.wrap:get()
    print(vim.opt.wrap:get() and "Wrap On" or "Wrap Off")
end, { desc = 'Toggle Line Wrap' })

-- Silicon (code screenshot)
map("v", "<leader>si", function() require("nvim-silicon").clip() end, { desc = "Silicon: copy selection to clipboard" })
map("n", "<leader>si", function() require("nvim-silicon").clip() end, { desc = "Silicon: copy whole file to clipboard" })

-- Telescope
map('n', '<leader>ff', function() require('telescope.builtin').find_files() end, { desc = 'Telescope find files' })
map('n', '<leader>fg', function() require('telescope.builtin').live_grep() end, { desc = 'Telescope live grep' })
map('n', '<leader>fb', function() require('telescope.builtin').buffers() end, { desc = 'Telescope buffers' })
map('n', '<leader>fh', function() require('telescope.builtin').help_tags() end, { desc = 'Telescope help tags' })

-- CompetiTest
map("n", "<leader>cr", "<cmd>CompetiTest run<CR>", { desc = "CompetiTest Run" })
map("n", "<leader>ca", "<cmd>CompetiTest add_testcase<CR>", { desc = "CompetiTest Add" })
map("n", "<leader>ce", "<cmd>CompetiTest edit_testcase<CR>", { desc = "CompetiTest Edit" })
map("n", "<leader>cd", "<cmd>CompetiTest delete_testcase<CR>", { desc = "CompetiTest Delete" })
map("n", "<leader>cp", "<cmd>CompetiTest receive<CR>", { desc = "CompetiTest Receive (Problem)" })
map("n", "<leader>r", function()
    if vim.bo.filetype == 'markdown' then
        require('configs.markdown_runner').run_codeblock()
    else
        vim.cmd('RunCode')
    end
end, { desc = "Run code / Run markdown codeblock" })

-- Typst
local typst_job = nil
map('n', '<leader>tc', function()
    if typst_job then
        vim.fn.jobstop(typst_job)
        typst_job = nil
        print("Typst watch stopped")
    else
        local file = vim.fn.expand('%:p')
        typst_job = vim.fn.jobstart(require('configs.typst').atomic_watch_command(file), { detach = false })
        print("Typst watch started: " .. file)
    end
end, { desc = 'Toggle typst watch' })

-- Abbreviations (C++ competitive programming)
vim.cmd [[
    inoreabbrev mian main
    inoreabbrev fori for(int i=1;i<=n;++i){}<left><C-R>
    inoreabbrev forj for(int j=1;j<=n;++j){}<left><C-R>
    inoreabbrev cin cin>><C-R>
    inoreabbrev cout cout<<<C-R>
    inoreabbrev lb lower_bound()<C-R>
    inoreabbrev ub upper_bound()<C-R>
    inoreabbrev be begin()<C-R>
    inoreabbrev en end()<C-R>
    inoreabbrev // /*  */<left><left><left><C-R>
    inoreabbrev #i #include <bits/stdc++.h><enter>using namespace std;<enter><enter>#define ll long long<enter>#define ld long double<enter>#define pii pair<int,int><enter>#define fi(_x) _x.first<enter>#define se(_x) _x.second<enter>const int N=200009;<enter><enter>void input(){<enter><enter>}<enter><enter>void solve(){<enter><enter>}<enter><enter>int main(){<enter>ios::sync_with_stdio(false);<enter>cin.tie(0);<enter>input();<enter>solve();<enter>return 0;<enter>}<C-R>
    inoreabbrev cr <cmd>CompetiTest run<CR>

    inoreabbrev <+ <=
    inoreabbrev >+ >=
    inoreabbrev +. plus.o
    inoreabbrev x. times.o
    inoreabbrev ca cal()<left><C-R>
    inoreabbrev fr frak()<left><C-R>
    inoreabbrev bo bold()<left><C-R>
    inoreabbrev sc scr()<left><C-R>
    inoreabbrev no. node((,),$$),
    inoreabbrev ed. edge((,),(,),"->"),
    inoreabbrev oof $oo$-范畴<C-R>

    inoreabbrev #d #definition(title:[])[<enter><enter>]<left><left><tab><left><left><left><left><left><left><C-R>
    inoreabbrev #t #theorem(title:[])[<enter><enter>]<left><left><tab><left><left><left><left><left><left><C-R>
    inoreabbrev #c #corollary[<enter><enter>]<left><left><tab><C-R>
    inoreabbrev #l #lemma[<enter><enter>]<left><left><tab><C-R>
    inoreabbrev #r #remark[<enter><enter>]<left><left><tab><C-R>
    inoreabbrev #p #proof[<enter><enter>]<left><left><tab><C-R>
]]
