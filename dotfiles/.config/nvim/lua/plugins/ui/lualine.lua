-- statusline
return {
   'nvim-lualine/lualine.nvim',
   event = 'VeryLazy',
   dependencies = {
      { 'kyazdani42/nvim-web-devicons' },
      { 'AndreM222/copilot-lualine' },
      {
         'letieu/harpoon-lualine',
         dependencies = {
            {
               'ThePrimeagen/harpoon',
               branch = 'harpoon2',
            },
         },
      },
   },
   init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
         -- set an empty statusline till lualine loads
         vim.o.statusline = ' '
      else
         -- hide the statusline on the starter page
         vim.o.laststatus = 0
      end
   end,
   opts = function()
      -- Inline `fg` utility function
      local function fg(name)
         ---@type {foreground?:number}?
         ---@diagnostic disable-next-line: deprecated
         local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name }) or vim.api.nvim_get_hl_by_name(name, true)
         ---@diagnostic disable-next-line: undefined-field
         local color = hl and (hl.fg or hl.foreground)
         return color and { fg = string.format('#%06x', color) } or nil
      end

      vim.o.laststatus = vim.g.lualine_laststatus

      return {
         options = {
            theme = 'auto',
            globalstatus = true,
            disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'starter' } },
            component_separators = { left = '|', right = '|' },
            section_separators = { left = '', right = '' },
         },
         sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch' },
            lualine_c = {
               {
                  'diagnostics',
                  symbols = {
                     error = ' ',
                     warn = ' ',
                     info = ' ',
                     hint = ' ',
                  },
               },
               { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
               '%=', -- center alignment
            },

            lualine_x = {

               {
                  function()
                     return require('noice').api.status.command.get()
                  end,
                  cond = function()
                     return package.loaded['noice'] and require('noice').api.status.command.has()
                  end,
                  color = fg 'Statement',
               },
               {
                  function()
                     return require('noice').api.status.mode.get()
                  end,
                  cond = function()
                     return package.loaded['noice'] and require('noice').api.status.mode.has()
                  end,
                  color = fg 'Constant',
               },
               {
                  function()
                     return '  ' .. require('dap').status()
                  end,
                  cond = function()
                     return package.loaded['dap'] and require('dap').status() ~= ''
                  end,
                  color = fg 'Debug',
               },
               {
                  'diff',
                  source = function()
                     local gitsigns = vim.b.gitsigns_status_dict
                     if gitsigns then
                        return {
                           added = gitsigns.added,
                           modified = gitsigns.changed,
                           removed = gitsigns.removed,
                        }
                     end
                  end,
               },
               {
                  'copilot',
                  -- Default values
                  symbols = {
                     status = {
                        icons = {
                           enabled = ' ',
                           sleep = ' ', -- auto-trigger disabled
                           disabled = ' ',
                           warning = ' ',
                           unknown = ' ',
                        },
                        hl = {
                           enabled = '#2ac3de',
                           sleep = '#2ac3de',
                           disabled = '#6272A4',
                           warning = '#FF5555',
                           unknown = '#FFB86C',
                        },
                     },
                     spinners = require('copilot-lualine.spinners').dots,
                     spinner_color = '#6272A4',
                  },
                  show_colors = true,
                  show_loading = true,
               },
               {
                  -- This function tracks the status of formatters and the
                  -- autoformat status of the current buffer and globally
                  -- through conform.nvim
                  -- TODO: color not working
                  function()
                     -- Check if 'conform' is available
                     local status, conform = pcall(require, 'conform')
                     if not status then
                        return 'Conform not installed'
                     end

                     local lsp_format = require 'conform.lsp_format'

                     -- Check auto format status
                     local autoformat_status = ''
                     local icon = ''
                     if vim.g.disable_autoformat then
                        autoformat_status = ' disabled (glob)'
                        icon = ' '
                        -- color = '#6272A4' -- Grey color
                     elseif vim.b.disable_autoformat then
                        autoformat_status = ' disabled (buf)'
                        icon = ' '
                        -- color = '#6272A4' -- Grey color
                     else
                        autoformat_status = ''
                        icon = '󰷈 '
                        -- color = '#2ac3de' -- Enabled color
                     end

                     -- Get formatters for the current buffer
                     local formatters = conform.list_formatters_for_buffer()
                     if formatters and #formatters > 0 then
                        local formatterNames = {}

                        for _, formatter in ipairs(formatters) do
                           table.insert(formatterNames, formatter)
                        end

                        return icon .. table.concat(formatterNames, ' ') .. autoformat_status
                     end

                     -- Check if there's an LSP formatter
                     local bufnr = vim.api.nvim_get_current_buf()
                     local lsp_clients = lsp_format.get_format_clients { bufnr = bufnr }

                     if not vim.tbl_isempty(lsp_clients) then
                        return ' 󰷈 LSP Formatter' .. autoformat_status
                     end

                     return autoformat_status
                  end,
               },
            },
            lualine_y = {
               { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
               { 'location', padding = { left = 0, right = 1 } },
            },
            lualine_z = {
               function()
                  return ' ' .. os.date '%R'
               end,
            },
         },
         extensions = { 'neo-tree', 'lazy' },
      }
   end,
}
