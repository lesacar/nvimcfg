vim.cmd([[
nnoremap d "_d
set clipboard=unnamedplus
set tabstop=4
set relativenumber
set shiftwidth=4
set smarttab
set softtabstop=4
]])
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{ 'nvim-telescope/telescope.nvim', tag = '0.1.5',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
	{ "jose-elias-alvarez/null-ls.nvim" },
	{ "hrsh7th/cmp-nvim-lsp"},
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "neovim/nvim-lspconfig" },
	{ "hrsh7th/vim-vsnip" },
	{ "hrsh7th/nvim-cmp",
		dependencies = {
			{
				"Saecki/crates.nvim",
				event = { "BufRead Cargo.toml" },
			},
		},
		---@param opts cmp.ConfigSchema
		opts = function(_, opts)
			opts.sources = opts.sources or {}
			table.insert(opts.sources, { name = "crates" })
		end,
	},
}
local opts = {}
require("lazy").setup(plugins, opts)
local builtin = require("telescope.builtin")
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})

local config = require("nvim-treesitter.configs")
config.setup({
	ensure_installed = {"lua", "c", "rust"},
	highlight = { enable = true },
	indent = { enable = true },
})

require("catppuccin").setup({
	transparent_background = true,
})
vim.cmd.colorscheme "catppuccin"
require("mason").setup()

require'cmp'.setup {
  sources = {
    { name = 'nvim_lsp' }
  }
}


local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("mason-lspconfig").setup {
    ensure_installed = {
		"rust_analyzer",
		"clangd"
	},
}

local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.diagnostics.eslint,
        null_ls.builtins.completion.spell,
    },
})



local lspconfig = require('lspconfig')
local cmp = require('cmp')

-- Setup nvim-cmp
cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
    },
    mapping = {
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }),
		['<Left>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
		['<Right>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),


    },
    sources = {
		{ name = "nvim_lsp", entry_filter = function(entry, ctx) 
		return require("cmp").lsp.CompletionItemKind.Text ~= entry:get_kind() end },
        { name = 'vsnip' },
    },
})

-- Configure and setup C/C++ language server
lspconfig.clangd.setup({
    cmd = { "clangd", "--background-index"},
	capabilities = capabilities,
    filetypes = { "c", "cpp" },
	root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
	settings = {
		clangd = {
			completion = {
				includeMacros = true
			}
		}
	}
})

lspconfig.glslls.setup({
	filetypes = { "fs", "vs", "frag", "vert", "glsl"},
})



lspconfig.rust_analyzer.setup({
})

require("lspconfig").lua_ls.setup {
  capabilities = capabilities,
  settings = {
    Lua = {
      format = {
        enable = true,
        -- Put format options here
        -- NOTE: the value should be STRING!!
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
        },
      },
    },
  },
}


-- local util = require "lspconfig/util"


-- Optionally, you can define additional key mappings for triggering completion manually
vim.api.nvim_set_keymap('i', '<C-Space>', 'v:lua.require("cmp").complete()', { expr = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>fd', ':lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.hover()<CR>', { expr = true, noremap = true })
