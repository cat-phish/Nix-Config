-- copilot
return {
   'zbirenbaum/copilot.lua',
   vim.api.nvim_set_hl(0, 'CopilotSuggestion', { fg = '#646D97' }),
   cmd = 'Copilot',
   build = ':Copilot auth',
   event = 'BufReadPost',
   config = function()
      require('copilot').setup {
         panel = {
            enabled = true,
            auto_refresh = true,
            keymap = {
               jump_prev = '[[',
               jump_next = ']]',
               accept = '<CR>',
               refresh = 'gr',
               open = '<M-BS>',
            },
            layout = {
               position = 'bottom', -- | top | left | right
               ratio = 0.4,
            },
         },
         suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 75,
            keymap = {
               accept = '<M-CR>',
               accept_word = false,
               accept_line = false,
               next = '<M-n>',
               prev = '<M-p>',
               dismiss = '<M-e>',
            },
         },
         filetypes = {
            yaml = true,
            markdown = true,
            help = false,
            gitcommit = false,
            gitrebase = false,
            hgcommit = false,
            svn = false,
            cvs = false,
            ['.'] = false,
            ['*'] = true,
         },
         copilot_node_command = 'node', -- Node.js version must be > 16.x
         server_opts_overrides = {},
      }
   end,
}
