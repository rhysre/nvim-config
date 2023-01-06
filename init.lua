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

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'clangd', 'zls', 'pylsp', 'gopls', 'bashls' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

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

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<Leader>ff', builtin.find_files, { desc = "find files" })
vim.keymap.set('n', '<Leader>lg', builtin.live_grep, { desc = "live grep" })

-- signature helper
require "lsp_signature".setup()

-- lsp ui stuff: TODO look into this later for more cool things to add
require 'lspsaga'.init_lsp_saga()

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
})

-- auto format for gopls
local go_org_imports = function(wait_ms)
  local params = vim.lsp.util.make_range_params()
  params.context = {only = {"source.organizeImports"}}
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
  for cid, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
        vim.lsp.util.apply_workspace_edit(r.edit, enc)
      end
    end
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.go',
  callback = function()
    vim.lsp.buf.formatting_sync()
    go_org_imports()
  end,
})
