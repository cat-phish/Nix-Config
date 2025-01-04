-- Formatting Plugin
local Util = require 'config.utils'
return {
   'stevearc/conform.nvim',
   event = { 'BufWritePre' },
   cmd = { 'ConformInfo' },
   keys = {
      {
         '<leader>cf',
         function()
            require('conform').format { async = true, lsp_format = 'fallback' }
         end,
         mode = '',
         desc = 'Format buffer',
      },
      {
         '<leader>of',
         function()
            if vim.b.disable_autoformat then
               vim.cmd 'FormatEnable'
               -- vim.notify('Enabled auto format for buffer', vim.log.levels.INFO, { title = 'Option' })
               Util.info('Enabled auto format for buffer', { title = 'Option' })
            else
               vim.cmd 'FormatDisable!'
               -- vim.notify('Disabled auto format for buffer', vim.log.levels.WARN, { title = 'Option' })
               Util.warn('Disabled auto format for buffer', { title = 'Option' })
            end
         end,
         mode = '',
         desc = 'Toggle Auto Format (Buffer)',
      },
      {
         '<leader>oF',
         function()
            if vim.g.disable_autoformat then
               vim.cmd 'FormatEnable'
               -- vim.notify('Enabled auto format globally', vim.log.levels.INFO, { title = 'Option' })
               Util.info('Enabled auto format globally', { title = 'Option' })
            else
               vim.cmd 'FormatDisable'
               -- vim.notify('Disabled auto format globally', vim.log.levels.WARN, { title = 'Option' })
               Util.warn('Disabled auto format globally', { title = 'Option' })
            end
         end,
         mode = '',
         desc = 'Toggle Auto Format (Global)',
      },
   },
   opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
         if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return false
         end
         -- Disable "format_on_save lsp_fallback" for languages that don't
         -- have a well standardized coding style. You can add additional
         -- languages here or re-enable it for the disabled ones.
         local disable_filetypes = {}
         local lsp_format_opt
         if disable_filetypes[vim.bo[bufnr].filetype] then
            lsp_format_opt = 'never'
         else
            lsp_format_opt = 'fallback'
         end
         return {
            timeout_ms = 500,
            lsp_format = lsp_format_opt,
         }
      end,
      formatters_by_ft = {
         bash = { 'beautysh' },
         cpp = { 'clang-format' },
         css = { 'prettier' },
         graphql = { 'prettier' },
         html = { 'prettier' },
         javascript = { 'prettierd', 'prettier', stop_after_first = true },
         javascriptreact = { 'prettier' },
         json = { 'prettier' },
         liquid = { 'prettier' },
         lua = { 'stylua' },
         markdown = { 'prettier' },
         python = { 'isort', 'black' },
         typescript = { 'prettier' },
         typescriptreact = { 'prettier' },
         yaml = { 'prettier' },
      },
   },
   config = function(_, opts)
      -- Initialize the global variable for auto format on save
      vim.g.disable_autoformat = false

      -- Set up conform.nvim with the provided options
      require('conform').setup(opts)

      -- Create Autoformat on save commands
      vim.api.nvim_create_user_command('FormatDisable', function(args)
         if args.bang then
            -- FormatDisable! will disable formatting just for this buffer
            vim.b.disable_autoformat = true
         else
            vim.g.disable_autoformat = true
         end
      end, {
         desc = 'Disable autoformat-on-save',
         bang = true,
      })

      vim.api.nvim_create_user_command('FormatEnable', function()
         vim.b.disable_autoformat = false
         vim.g.disable_autoformat = false
      end, {
         desc = 'Re-enable autoformat-on-save',
      })
   end,
}
