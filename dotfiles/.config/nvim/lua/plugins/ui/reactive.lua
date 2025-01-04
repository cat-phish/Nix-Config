-- Dynamic statusline color modifications
return {
   'rasulomaroff/reactive.nvim',
   config = function()
      require('reactive').setup {
         -- builtin = {
         --    cursorline = true,
         --    cursor = true,
         --    modemsg = true,
         -- },
      }
      require('reactive').add_preset {
         name = 'cursorline',
         init = function()
            vim.opt.guicursor:append 'a:ReactiveCursor'
         end,
         static = {
            winhl = {
               inactive = {
                  CursorLine = { bg = '#202020' },
                  CursorLineNr = { fg = '#b0b0b0', bg = '#202020' },
               },
            },
         },
         modes = {
            no = {
               operators = {
                  -- switch case
                  [{ 'gu', 'gU', 'g~', '~' }] = {
                     winhl = {
                        CursorLine = { bg = '#334155' },
                        CursorLineNr = { fg = '#cbd5e1', bg = '#334155' },
                     },
                  },
                  -- change
                  c = {
                     winhl = {
                        CursorLine = { bg = '#162044' },
                        CursorLineNr = { fg = '#93c5fd', bg = '#162044' },
                     },
                  },
                  -- delete
                  d = {
                     winhl = {
                        CursorLine = { bg = '#350808' },
                        CursorLineNr = { fg = '#fca5a5', bg = '#350808' },
                     },
                  },
                  -- yank
                  y = {
                     winhl = {
                        CursorLine = { bg = '#422006' },
                        CursorLineNr = { fg = '#fdba74', bg = '#422006' },
                     },
                  },
               },
            },
            i = {
               winhl = {
                  CursorLine = { bg = '#012828' }, --was #012828
                  CursorLineNr = { fg = '#afd75f', bg = '#012828' },
               },
               hl = {
                  ReactiveCursor = { bg = '#5eead4' },
               },
            },
            c = {
               winhl = {
                  CursorLine = { bg = '#793b0b' },
                  CursorLineNr = { fg = '#d1d4dc', bg = '#793b0b' },
               },
            },
            n = {
               winhl = {
                  CursorLine = { bg = '#000038' }, -- was #21202e
                  CursorLineNr = { fg = '#d1d4dc', bg = '#000038' },
               },
               hl = {
                  ReactiveCursor = { bg = '#d1d4dc' },
               },
            },
            -- visual
            [{ 'v', 'V', '\x16' }] = {
               winhl = {
                  CursorLineNr = { fg = '#bb9af7' },
                  Visual = { bg = '#3b0764' },
               },
            },
            -- select
            [{ 's', 'S', '\x13' }] = {
               winhl = {
                  CursorLineNr = { fg = '#c4b5fd' },
                  Visual = { bg = '#2e1065' },
               },
            },
            -- replace
            R = {
               winhl = {
                  CursorLine = { bg = '#95240e' },
                  CursorLineNr = { fg = '#d1d4dc', bg = '#95240e' },
               },
               hl = {
                  ReactiveCursor = { bg = '#ff8787' },
               },
            },
         },
      }
      require('reactive').load_preset 'main'
   end,
}
