require "nvchad.options"

local opt = vim.opt

-- Neovide: keep glyphs opaque while the editor canvas is transparent.
if vim.g.neovide then
    vim.g.neovide_opacity = 1.0
    vim.g.neovide_normal_opacity = 0.0
    vim.o.guifont = "JetBrainsMono Nerd Font,LXGW WenKai Screen:h11"
end

opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true
opt.timeoutlen = 250
opt.conceallevel = 2
opt.wrap = true
opt.showbreak = ' '
opt.breakindent = true
opt.breakindentopt = 'list:-1'

-- Popup / floating window transparency (0 = opaque, 100 = fully transparent)
opt.pumblend  = 40   -- completion menu
opt.winblend  = 40   -- floating windows (LSP hover, diagnostics, etc.)
