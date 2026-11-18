vim.cmd(':colo retrobox')

-- :h completeopt
-- :h lsp-completion
-- :h lsp-attach
vim.o.completeopt = 'menuone,noselect,popup'
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, {autotrigger = true})
    end
  end,
})

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.relativenumber = true

vim.o.shiftwidth = 4
vim.o.softtabstop = -1
vim.o.expandtab = true

vim.o.laststatus = 3

vim.o.winborder = 'rounded'

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('n', '<leader>q', '<cmd>q<cr>')
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>')

vim.keymap.set('n', 'gd', vim.lsp.buf.definition)

vim.diagnostic.config({ virtual_text = true })

-- :h vim.pack-examples
vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/tpope/vim-surround',
  'https://github.com/neovim/nvim-lspconfig',
})

vim.lsp.config('roslyn_ls', {
  cmd = { vim.fn.expand('~/.dotnet/tools/roslyn-language-server'), '--stdio' },
})

vim.lsp.enable({
  -- 'roslyn_ls',
  'ols',
})

-- Telescope: fuzzy finding
local telescope = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', telescope.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fh', telescope.help_tags, { desc = 'Telescope find help tags' })
vim.keymap.set('n', '<leader>fb', telescope.buffers, { desc = 'Telescope find buffers' })
vim.keymap.set('n', '<leader>fn', function()
  telescope.find_files({
    cwd = vim.fn.stdpath('config'),
  })
end, { desc = 'Telescope find config files' })
vim.keymap.set('n', '<leader>ss', telescope.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>ss', telescope.live_grep, { desc = 'Telescope live grep' })

-- Oil: edit directories like buffers
require('oil').setup()
vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })

-- User mods

local gateway_logstream = require('user.logstream.window')
gateway_logstream.efm = '%f(%l\\,%c): error %.%#: %m'
local prefix_len = #'gateway  | '
vim.keymap.set('n', '<leader>go', function()
  gateway_logstream:open(
    { 'docker', 'compose', 'logs', 'gateway', '-f' },
    {
      cwd = vim.fn.getcwd() .. '/src',
      line_mapper = function(line)
        local line, _ = string.sub(line, prefix_len+1)
        local line, _ = string.gsub(line, '/src/', vim.fn.getcwd() .. '/src/')
        return line
      end,
    }
  )
end)
vim.keymap.set('n', '<leader>gs', function() gateway_logstream:close() end)
vim.keymap.set('n', '<leader>gf', function() gateway_logstream:open_quickfix() end)

vim.api.nvim_create_user_command('Today', function(_)
  local path = vim.fn.expand('~/journal') .. '/' .. os.date("%Y/%m/%d") .. '.gmi'
  vim.cmd.edit(path)
end, { desc = "Edit today's journal entry"})

vim.api.nvim_create_user_command('Tour', function(_)
  local path = vim.fn.expand('~/journal/lists/tour.gmi')
  vim.cmd.edit(path)
end, { desc = "Edit the tour list"})
