local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
	vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()
local packer = require'packer'
local util = require'packer.util'
packer.init({
  package_root = util.join_paths(vim.fn.stdpath('data'), 'site', 'pack')
})

-- needs to be relatively high up
vim.g.mapleader = " "

--- startup and add configure plugins
packer.startup(function()
  local use = use
  use 'wbthomason/packer.nvim' -- Package manager
  use 'neovim/nvim-lspconfig' -- Collection of configurations for the built-in LSP client
  use 'ellisonleao/gruvbox.nvim' -- color scheme
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'nvim-treesitter/nvim-treesitter-context'
  use 'ntpeters/vim-better-whitespace'
  use 'ray-x/lsp_signature.nvim'
  use 'glepnir/lspsaga.nvim'
  use { 'fatih/vim-go', run = ':GoUpdateBinaries' }

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use {
    'vim-airline/vim-airline', -- status line
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end

  end
)

require'nvim-treesitter.configs'.setup {
  --ensure_installed = "maintained",
  sync_install = false,
  highlight = {
    enable = true,
    disable = { 'zig' },
    additional_vim_regex_highlighting = false,
  },
}

require'treesitter-context'.setup()

local lspconfig = require('lspconfig')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)

  vim.keymap.set('n', '<leader>gc', ':GoCoverageToggle<cr>', bufopts)
end

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'zls', 'pylsp', 'gopls', 'bashls' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Not currently using yamlls, but leave this here in case I do in the future
--[[
lspconfig.yamlls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    yaml = {
      schemas = {
        kubernetes = "*",
      },
      --schemaStore = {
      --  enable = true,
      --},
    },
  },
}
]]

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<Leader>ff', builtin.find_files, { desc = "find files" })
vim.keymap.set('n', '<Leader>lg', builtin.live_grep, { desc = "live grep" })
vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)

-- signature helper
require "lsp_signature".setup()

-- lsp ui stuff: TODO look into this later for more cool things to add
require('lspsaga').setup({})

-- basic vim options
vim.cmd('colorscheme gruvbox')
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.linebreak = true
vim.opt.shiftwidth = 4
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.timeoutlen = 250

-- I like just having one file for all my neovim configs, so effectively implementing ftplugin here
local function ftplugin(filetype, opts)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = filetype,
    callback = function()
      for key, value in pairs(opts) do
        vim.opt[key] = value
      end
    end,
  })
end

ftplugin('lua', {
  shiftwidth = 2,
})

ftplugin('markdown', {
  shiftwidth = 2,
  wrap = true,
})

ftplugin('asciidoc', {
  formatoptions = 'tcqr',
  shiftwidth = 2,
  wrap = true,
})

ftplugin('go', {
  tabstop = 4,
  expandtab = false
})
