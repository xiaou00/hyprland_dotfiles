return {
    {
        "stevearc/conform.nvim",
        opts = require "configs.conform"
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "configs.lspconfig"
        end
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup {}
        end
    },
    {
        'nvim-telescope/telescope.nvim', version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        }
    },
    {
        "folke/which-key.nvim",
        enabled = false,
    },
    {
        "github/copilot.vim",
        cmd = "Copilot",
        lazy = false,
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
        build = 'git apply --ignore-whitespace ' .. vim.fn.stdpath('config') .. '/patches/render-markdown-latex.patch || true',
        cmd = "RenderMarkdown",
        lazy = false,
        opts = {
            anti_conceal = { enabled = false },
            heading = { enabled = false },
            quote = { repeat_linebreak = true },
            callout = {
                def  = { raw = '[!DEF]',  rendered = '≝ Definition',  highlight = 'RenderMarkdownDef'  },
                thm  = { raw = '[!THM]',  rendered = '⊢ Theorem',     highlight = 'RenderMarkdownThm'  },
                lem  = { raw = '[!LEM]',  rendered = '◈ Lemma',        highlight = 'RenderMarkdownLem'  },
                prop = { raw = '[!PROP]', rendered = '◇ Proposition',  highlight = 'RenderMarkdownProp' },
                col  = { raw = '[!COL]',  rendered = '∴ Corollary',    highlight = 'RenderMarkdownCol'  },
                pf   = { raw = '[!PF]',   rendered = '□ Proof',        highlight = 'RenderMarkdownPf'   },
            },
            latex = {
                enabled = true,
                render_modes = false,
                converter = { 'utftex-clean', 'latex2text' },
                highlight = 'RenderMarkdownMath',
                position = 'center',
                top_pad = 0,
                bottom_pad = 0,
            },
            code = {
                enabled = true,
                render_modes = false,
                sign = true,
                conceal_delimiters = true,
                language = true,
                position = 'left',
                language_icon = true,
                language_name = true,
                language_info = true,
                language_pad = 0,
                disable = {},
                disable_background = { 'diff' },
                width = 'full',
                left_margin = 0,
                left_pad = 0,
                right_pad = 0,
                min_width = 0,
                border = 'hide',
                language_border = '█',
                language_left = '',
                language_right = '',
                above = '▄',
                below = '▀',
                inline = true,
                inline_left = '',
                inline_right = '',
                inline_pad = 0,
                priority = 140,
                highlight = 'RenderMarkdownCode',
                highlight_info = 'RenderMarkdownCodeInfo',
                highlight_language = nil,
                highlight_border = 'RenderMarkdownCodeBorder',
                highlight_fallback = 'RenderMarkdownCodeFallback',
                highlight_inline = 'RenderMarkdownCodeInline',
                style = 'full',
            },
        },
    },
    {
        'Julian/lean.nvim',
        event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = { mappings = true },
    },
    { "petRUShka/vim-sage" },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = { "vim", "lua", "vimdoc", "html", "css", "cpp", "c", "python", "latex", "typst" },
            highlight = {
                enable = true,
                use_languagetree = true,
            },
            indent = { enable = true },
        },
    },
    {
        "lervag/vimtex",
        lazy = false,
        config = function()
            vim.g.vimtex_view_method = 'zathura'
            vim.g.vimtex_compiler_method = 'latexmk'
            vim.g.vimtex_compiler_latexmk = {
                options = {
                    '-shell-escape',
                    '-verbose',
                    '-file-line-error',
                    '-synctex=1',
                    '-interaction=nonstopmode',
                    '-xelatex',
                },
            }
        end
    },
    {
        "CRAG666/code_runner.nvim",
        cmd = { "RunCode" },
        opts = {
            filetype = {
                cpp = {
                    "cd $dir &&",
                    "g++ $fileName -o $fileNameWithoutExt &&",
                    "time ./$fileNameWithoutExt ;",
                    "rm $fileNameWithoutExt",
                },
                sage = {
                    "cd $dir &&",
                    "sage $fileName",
                },
            },
        },
    },
    {
        'xeluxee/competitest.nvim',
        dependencies = 'MunifTanjim/nui.nvim',
        ft = { "cpp", "c" },
        config = function()
            require('competitest').setup {
                local_config_file_name = ".competitest.lua",
                floating_border = "rounded",
                floating_border_highlight = "FloatBorder",
                picker_ui = {
                    width = 0.2,
                    height = 0.3,
                    mappings = {
                        focus_next = { "j", "<down>", "<Tab>" },
                        focus_prev = { "k", "<up>", "<S-Tab>" },
                        close = { "<esc>", "<C-c>", "q", "Q" },
                        submit = "<cr>"
                    }
                },
                editor_ui = {
                    popup_width = 0.4,
                    popup_height = 0.6,
                    show_nu = true,
                    show_rnu = false,
                    normal_mode_mappings = {
                        switch_window = { "<C-h>", "<C-l>", "<C-i>" },
                        save_and_close = "<C-s>",
                        cancel = { "q", "Q" }
                    },
                    insert_mode_mappings = {
                        switch_window = { "<C-h>", "<C-l>", "<C-i>" },
                        save_and_close = "<C-s>",
                        cancel = "<C-q>"
                    }
                },
                focus_on_run = true,
                runner_ui = {
                    interface = "popup",
                    selector_show_nu = false,
                    selector_show_rnu = false,
                    show_nu = true,
                    show_rnu = false,
                    mappings = {
                        ui_close = 'q',
                        terminal_close = 'q',
                        run_again = "R",
                        run_all_again = "<C-r>",
                        kill = "K",
                        kill_all = "<C-k>",
                        view_input = { "i", "I" },
                        view_output = { "a", "A" },
                        view_stdout = { "o", "O" },
                        view_stderr = { "e", "E" },
                        toggle_diff = { "d", "D" },
                        close = { "q", "Q" }
                    },
                    viewer = {
                        width = 0.5,
                        height = 0.5,
                        show_nu = true,
                        show_rnu = false,
                        open_when_compilation_fails = true
                    }
                },
                popup_ui = {
                    total_width = 0.8,
                    total_height = 0.8,
                    layout = { { 4, "tc" }, { 5, { { 1, "so" }, { 1, "si" } } }, { 5, { { 1, "eo" }, { 1, "se" } } } }
                },
                split_ui = {
                    position = "right",
                    relative_to_editor = true,
                    total_width = 0.3,
                    vertical_layout = { { 1, "tc" }, { 1, { { 1, "so" }, { 1, "eo" } } }, { 1, { { 1, "si" }, { 1, "se" } } } },
                    total_height = 0.4,
                    horizontal_layout = { { 2, "tc" }, { 3, { { 1, "so" }, { 1, "si" } } }, { 3, { { 1, "eo" }, { 1, "se" } } } }
                },
                save_current_file = true,
                save_all_files = false,
                compile_directory = ".",
                compile_command = {
                    c = { exec = "gcc", args = { "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" } },
                    cpp = { exec = "g++", args = { "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" } },
                    rust = { exec = "rustc", args = { "$(FNAME)" } },
                    java = { exec = "javac", args = { "$(FNAME)" } }
                },
                running_directory = ".",
                run_command = {
                    c = { exec = "./$(FNOEXT)" },
                    cpp = { exec = "./$(FNOEXT)" },
                    rust = { exec = "./$(FNOEXT)" },
                    python = { exec = "python", args = { "$(FNAME)" } },
                    java = { exec = "java", args = { "$(FNOEXT)" } }
                },
                multiple_testing = -1,
                maximum_time = 5000,
                output_compare_method = "squish",
                view_output_diff = false,
                testcases_directory = ".",
                testcases_use_single_file = false,
                testcases_auto_detect_storage = true,
                testcases_single_file_format = "$(FNOEXT).testcases",
                testcases_input_file_format = "$(FNOEXT)_input$(TCNUM).txt",
                testcases_output_file_format = "$(FNOEXT)_output$(TCNUM).txt",
                companion_port = 27121,
                receive_print_message = true,
                start_receiving_persistently_on_setup = false,
                template_file = false,
                evaluate_template_modifiers = false,
                date_format = "%c",
                received_files_extension = "cpp",
                received_problems_path = "$(CWD)/$(PROBLEM).$(FEXT)",
                received_problems_prompt_path = true,
                received_contests_directory = "$(CWD)",
                received_contests_problems_path = "$(PROBLEM).$(FEXT)",
                received_contests_prompt_directory = true,
                received_contests_prompt_extension = true,
                open_received_problems = true,
                open_received_contests = true,
                replace_received_testcases = false
            }
        end,
    },
    {
        "akinsho/flutter-tools.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "stevearc/dressing.nvim",
        },
        config = function()
            require("flutter-tools").setup({
                ui = {
                    border = "rounded",
                    notification_style = "plugin"
                },
                decorations = {
                    statusline = {
                        app_version = true,
                        device = true,
                    }
                },
                lsp = {
                    color = {
                        enabled = true,
                        background = false,
                        foreground = false,
                        virtual_text = true,
                    },
                },
                debugger = {
                    enabled = true,
                    run_via_dap = true,
                },
            })
        end,
    },
    {
        "michaelrommel/nvim-silicon",
        lazy = true,
        cmd = "Silicon",
        config = function()
            require("nvim-silicon").setup({
                font = "JetBrainsMono Nerd Font=34;Source Han Sans CN=34;Noto Color Emoji=34",
                theme = vim.fn.expand("~/.config/silicon/themes/obsidian-ember.tmTheme"),
                background = "#101018",
                to_clipboard = true,
                window_title = function()
                    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
                end,
                line_offset = function(args)
                    return args.line1
                end,
            })
        end,
    },
    {
        "goolord/alpha-nvim",
        lazy = false,
        config = function()
            require('alpha').setup(require('alpha.themes.dashboard').config)
        end
    },
    {
        "sevenc-nanashi/neov-ime.nvim",
        cond = vim.g.neovide,
    },
    {
        "chomosuke/typst-preview.nvim",
        lazy = false,
        version = "1.*",
        opts = {
            open_cmd = "/usr/bin/chromium --disable-gpu --app=%s",
            invert_colors = "always",
            get_root = require("configs.typst").root,
            dependencies_bin = {
                tinymist = "tinymist",
            }
        },
    },
    --{
    --    dir = "/home/xiaou0/Projects/LuaProjects/typst-math-preview.nvim",
    --    ft = "typst",
    --},
}
