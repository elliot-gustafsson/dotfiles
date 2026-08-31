-- Set the Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic Neovim Settings
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.keymodel = "startsel,stopsel"
vim.opt.clipboard = "unnamedplus"
vim.opt.fixendofline = true
vim.opt.exrc = true -- Allow project-specific .nvim.lua files

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim and Load Plugins
require("lazy").setup({

	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Tell our servers we support autocompletion
			local capabilities = require('cmp_nvim_lsp').default_capabilities()

			vim.lsp.config('gopls', {
				capabilities = capabilities,
				settings = {
					gopls = {
						analyses = {
							unusedparams = true,
							shadow = true
						},
						staticcheck = true,
						-- gofumpt = true
					}
				},
			})

			vim.lsp.config('dockerls', {
				capabilities = capabilities
			})

			local k8s_schema_url =
			"https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.33.5-standalone-strict/all.json"

			vim.lsp.config('jsonls', {
				capabilities = capabilities
			})

			vim.lsp.config('yamlls', {
				capabilities = capabilities,
				settings = {
					yaml = {
						completion = true,
						format = {
							bracketSpacing = false,
						},
						-- maxItemsComputed = 100000,
						suggest = {
							parentSkeletonSelectedFirst = true,
						},
						trace = {
							server = "messages",
						},
						schemas = {
							kubernetes = { "" },
							-- [k8s_schema_url] = {
							-- 	-- "kube/*.yml",
							-- 	-- "kube/*.yaml",
							-- 	"*.yml",
							-- 	"*.yaml"
							-- }
						}
					}
				},
				on_init = function(client)
					-- Grab your local paths (or use defaults)
					local kube_paths = vim.g.kube_yaml_paths or {
						"kube/*.yml",
						"kube/*.yaml"
					}

					-- Inject the dynamic schema directly into the client's active settings
					client.config.settings.yaml.schemas[k8s_schema_url] = kube_paths

					-- Notify the server immediately that its configuration has changed
					client.notify("workspace/didChangeConfiguration", {
						settings = client.config.settings
					})

					return true
				end
			})

			vim.lsp.config('jsonnet_ls', {
				capabilities = capabilities
			})
		end
	},

	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗"
					}
				}
			})

			require("mason-lspconfig").setup({
				ensure_installed = {
					-- Add your LSP servers here (e.g., "ts_ls", "pyright", "rust_analyzer")
					"lua_ls",
					"gopls",
					"yamlls",
					"dockerls",
					"jsonls",
					"jsonnet_ls",
					"intelephense",
				},
				automatic_installation = true,
			})

			-- Customize specific servers

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = { diagnostics = { globals = { "vim" } } }
				}
			})

			-- Note: If a specific, obscure language server hasn't been updated to the
			-- new API yet, you can still fall back to the old way for that specific server:
			-- require("lspconfig").some_server.setup({})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = false,
		config = function()
			local treesitter = require("nvim-treesitter")

			local languages = {
				'dockerfile',
				'c',
				'cpp',
				'go',
				'gomod',
				'lua',
				'python',
				-- 'rust',
				-- 'typescript',
				-- 'typescriptreact',
				-- 'tsx',
				'sql',
				'html',
				'javascript',
				'vimdoc',
				'vim',
				'php',
				'comment',
				'yaml',
				'bash',
				'jsonnet',
				'json',
				'http',
				'java',
				'groovy',
			}
			treesitter.install(languages)

			vim.api.nvim_create_autocmd('FileType', {
				pattern = languages,
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end
	},

	{
		"HiPhish/rainbow-delimiters.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		-- event = "LazyFile",
		config = function()
			local rainbow_delimiters = require("rainbow-delimiters")

			-- rainbow-delimiters doesn't use a standard setup() function;
			-- instead, it reads from a global variable.
			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
					vim = rainbow_delimiters.strategy["local"],
				},
				query = {
					[""] = "rainbow-delimiters",
					-- lua = "rainbow-blocks",
				},
				priority = {
					[""] = 110,
					lua = 210,
				},
				highlight = {
					"RainbowDelimiterYellow",
					"RainbowDelimiterPink",
					"RainbowDelimiterBlue",
				},
			}
		end,
	},

	-- Telescope (Fuzzy Finder)
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require('telescope.builtin')
			vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
			vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
			vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
			vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
		end
	},
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			require('lualine').setup({
				inactive_sections = {
					lualine_c = {
						{
							'filename',
							path = 1,
							shorting_target = 10,
						}
					},
				}
			})
		end
	},
	-- Git Integration (Inline Blame & Gutter Signs)
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require('gitsigns').setup {
				signs                        = {
					add          = { text = '┃' },
					change       = { text = '┃' },
					delete       = { text = '_' },
					topdelete    = { text = '‾' },
					changedelete = { text = '~' },
					untracked    = { text = '┆' },
				},
				signs_staged                 = {
					add          = { text = '┃' },
					change       = { text = '┃' },
					delete       = { text = '_' },
					topdelete    = { text = '‾' },
					changedelete = { text = '~' },
					untracked    = { text = '┆' },
				},
				signs_staged_enable          = true,
				signcolumn                   = true, -- Toggle with `:Gitsigns toggle_signs`
				numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
				linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
				word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
				watch_gitdir                 = {
					follow_files = true
				},
				auto_attach                  = true,
				attach_to_untracked          = false,
				current_line_blame           = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
				current_line_blame_opts      = {
					virt_text = true,
					virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
					delay = 1000,
					ignore_whitespace = false,
					virt_text_priority = 100,
					use_focus = true,
				},
				current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
				sign_priority                = 6,
				update_debounce              = 100,
				status_formatter             = nil, -- Use default
				max_file_length              = 40000, -- Disable if file is longer than this (in lines)
				preview_config               = {
					-- Options passed to nvim_open_win
					style = 'minimal',
					relative = 'cursor',
					row = 0,
					col = 1
				},
			}
		end
	},

	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip", },
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
				mapping = cmp.mapping.preset.insert({
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<CR>'] = cmp.mapping.confirm({ select = true }),
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' }),
				}),
				sources = cmp.config.sources(
					{ { name = 'nvim_lsp' }, { name = 'luasnip' } },
					{ { name = 'buffer' }, { name = 'path' } }
				),
				window = {
					-- Adds a clean border to the main autocomplete dropdown
					completion = cmp.config.window.bordered({
						border = "single", -- Can be "single", "double", "rounded", "solid", etc.
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
					}),

					-- Adds a clean border to the documentation window, creating a gap
					documentation = cmp.config.window.bordered({
						border = "single",
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
					}),
				},
			})
		end
	},
	-- Formatting Plugin
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					go = { "goimports", "gofmt" },
					lua = { "stylua" },
					jsonnet = { "jsonnetfmt" },
					libsonnet = { "jsonnetfmt" },
					python = { "isort", "black" },
					php = { "phpcbf" }
					-- You can add formatters for json or yaml here later if you want (like "prettier")
				},
				format_on_save = {
					timeout_ms = 1000,
					lsp_fallback = true
				},
			})
		end
	},
})


-- ==========================================
-- PLUGIN CONFIGURATIONS
-- ==========================================

-- 'd' and 'c' go to the black hole (No clipboard overwriting)
vim.keymap.set({ "n", "v" }, "d", "\"_d", { desc = "Delete to black hole" })
vim.keymap.set("n", "D", "\"_D", { desc = "Delete line to black hole" })
vim.keymap.set({ "n", "v" }, "c", "\"_c", { desc = "Change to black hole" })
vim.keymap.set("n", "C", "\"_C", { desc = "Change line to black hole" })

-- 'x' becomes your new Cut operator (Sends to system clipboard)
vim.keymap.set({ "n", "v" }, "x", "\"+d", { desc = "Cut to clipboard" })
vim.keymap.set("n", "xx", "\"+dd", { desc = "Cut line to clipboard" })
vim.keymap.set("n", "X", "\"+D", { desc = "Cut to end of line to clipboard" })

-- Save file with Ctrl+S in Normal, Insert, and Visual modes
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", { desc = "Save file" })

vim.keymap.set('n', '<C-z>', 'u', { desc = 'Undo' })
vim.keymap.set('i', '<C-z>', '<C-o>u', { desc = 'Undo' })
vim.keymap.set('v', '<C-z>', '<Esc>u', { desc = 'Undo' })
vim.keymap.set('n', '<C-S-z>', '<C-r>', { desc = 'Redo' })
vim.keymap.set('i', '<C-S-z>', '<C-o><C-r>', { desc = 'Redo' })
vim.keymap.set('v', '<C-S-z>', '<Esc><C-r>', { desc = 'Redo' })

-- -- Press Ctrl+b to toggle the full-file Git blame window
-- vim.keymap.set('n', '<C-b>', '<cmd>Gitsigns blame<CR>', { desc = 'Toggle Git Blame File' })

-- Smart Toggle for the full-file Git blame window
vim.keymap.set('n', '<C-b>', function()
	local blame_closed = false
	-- Check all windows in the current tab
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		-- If we find the blame window, close it
		if vim.bo[buf].filetype == "gitsigns-blame" then
			vim.api.nvim_win_close(win, true)
			blame_closed = true
		end
	end

	-- If it wasn't open, open it now
	if not blame_closed then
		vim.cmd("Gitsigns blame")
	end
end, { desc = "Toggle Git Blame File" })

-- Set up LSP navigation keymaps
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		local opts = { buffer = ev.buf, silent = true }

		-- Navigation
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
		vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
	end,
})

-- Trim trailing newlines
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		local save_cursor = vim.fn.getpos(".")

		-- 1. Trim trailing whitespace from the ends of lines
		vim.cmd([[%s/\s\+$//e]])

		-- 2. Delete extra blank lines at the bottom of the file
		local n_lines = vim.api.nvim_buf_line_count(0)
		local last_nonblank = vim.fn.prevnonblank(n_lines)

		-- As long as the file has text, delete everything below the last text line.
		-- Neovim's 'fixendofline' will automatically add the single final newline.
		if last_nonblank > 0 and last_nonblank < n_lines then
			vim.api.nvim_buf_set_lines(0, last_nonblank, n_lines, false, {})
		end

		vim.fn.setpos(".", save_cursor)
	end,
})

vim.diagnostic.config({
	-- This is the magic toggle that shows inline error messages
	virtual_text = {
		prefix = '', -- Changes the prefix to a nice dot instead of standard text
		spacing = 4, -- Adds a bit of breathing room between code and the error
	},

	-- Keeps the 'E' or 'W' icons in the left gutter
	signs = true,

	-- Underlines the specific word or variable causing the issue
	underline = true,

	-- False: Wait until you exit Insert mode to show new errors (less distracting)
	-- True: Show errors immediately as you type
	update_in_insert = true,

	-- Sorts diagnostics so that Errors always take visual priority over Warnings
	severity_sort = true,
})


-- File: ~/.config/nvim/colors/darcula_custom.lua

vim.o.termguicolors = true
vim.g.colors_name = "darcula_custom"

-- Define the palette based on your VS Code settings
local colors = {
	-- Syntax Colors
	orange          = "#CC7832", -- Keywords, built-in types, escapes
	green           = "#4e8a63", -- Strings, phpdoc
	yellow          = "#FFC66D", -- Functions, Methods
	cyan            = "#2aacB8", -- Numbers
	blue            = "#6fafbd", -- Custom Types / Structs / Interfaces
	purple          = "#9876AA", -- PHP vars, global constants
	pink            = "#c77dbb", -- Properties, struct fields
	olive           = "#AFBF7E", -- Namespaces / Modules / Packages
	olive_dark      = "#aca547", -- Attributes
	grey_comment    = "#7a7e85", -- Comments
	grey_class      = "#b2b7bd", -- Classes, imports
	fg_main         = "#bcbec4", -- Standard variables, foreground, punctuation
	fg_light        = "#D4D4D4", -- Operators, PHP arrows

	-- UI Backgrounds & Accents
	bg_editor       = "#2b2b2b",
	bg_gutter       = "#222222",
	bg_sidebar      = "#2c2c2c",
	bg_popup        = "#3c3f41",
	visual_sel      = "#214283",
	indent_active   = "#007ACC",
	indent_inactive = "#4e4e4e",
}

-- Map the colors to Neovim highlight groups

local highlights = {
	---------------------------------------------------------
	-- Core Editor & UI Backgrounds
	---------------------------------------------------------
	Normal                    = { fg = colors.fg_main, bg = colors.bg_editor },
	NormalFloat               = { fg = colors.fg_main, bg = colors.bg_editor },
	LineNr                    = { fg = colors.grey_comment, bg = colors.bg_gutter },
	SignColumn                = { bg = colors.bg_gutter },
	StatusLine                = { bg = colors.bg_editor },
	StatusLineNC              = { bg = colors.bg_editor },
	NvimTreeNormal            = { fg = colors.fg_main, bg = colors.bg_sidebar },
	NvimTreeEndOfBuffer       = { fg = colors.bg_sidebar, bg = colors.bg_sidebar },
	Terminal                  = { bg = colors.bg_gutter },
	Visual                    = { bg = colors.visual_sel },
	Search                    = { bg = "#32593d" },
	MatchParen                = { bg = "#3b514d", bold = true },

	-- Popups & Autocompletion
	Pmenu                     = { fg = colors.fg_main, bg = colors.bg_popup },
	PmenuSel                  = { fg = "#ffffff", bg = colors.visual_sel },

	-- Indent Guides (if using indent-blankline.nvim)
	IblIndent                 = { fg = colors.indent_inactive },
	IblScope                  = { fg = colors.indent_active },

	RainbowDelimiterYellow    = { fg = "#FFD700" },
	RainbowDelimiterPink      = { fg = "#DA70D6" },
	RainbowDelimiterBlue      = { fg = "#1E90FF" },

	---------------------------------------------------------
	-- Standard Syntax & General Overrides
	---------------------------------------------------------

	Identifier                = { fg = colors.fg_main },
	["@variable"]             = { fg = colors.fg_main },
	["@property"]             = { fg = colors.fg_main },
	["@constructor"]          = { fg = colors.fg_main },

	["@string"]               = { fg = colors.green },

	Keyword                   = { fg = colors.orange },
	-- Special                   = { fg = colors.orange },
	["@keyword"]              = { fg = colors.orange },
	["@type.builtin"]         = { fg = colors.orange },
	["@constant.builtin"]     = { fg = colors.orange },
	["@function.builtin"]     = { fg = colors.orange },
	["@variable.builtin"]     = { fg = colors.orange },
	["@boolean"]              = { fg = colors.orange },

	["@function"]             = { fg = colors.yellow },

	["@number"]               = { fg = colors.cyan },

	["@comment"]              = { fg = colors.grey_comment },

	["@module"]               = { fg = colors.olive },

	Special                   = { fg = colors.blue },
	["@type"]                 = { fg = colors.blue },

	Constant                  = { fg = colors.pink },
	["@constant"]             = { fg = colors.pink },

	["@attribute"]            = { fg = colors.olive_dark },
	["@tag"]                  = { fg = colors.olive_dark },
	--
	-- PHP
	["@variable.php"]         = { fg = colors.purple },
	["@variable.builtin.php"] = { fg = colors.purple },
	["@property.php"]         = { fg = colors.purple },
	["@constant.builtin.php"] = { fg = colors.orange },
	-- ["@variable.parameter.php"] = { fg = colors.purple },
	["@variable.member.php"]  = { fg = colors.pink },
	["@constructor.php"]      = { fg = colors.fg_main },
	["@type.php"]             = { fg = colors.fg_main },

	-- GO
	-- ["@variable.go"]            = { fg = colors.olive },
}

-- Apply the highlights globally
for group, settings in pairs(highlights) do
	vim.api.nvim_set_hl(0, group, settings)
end
