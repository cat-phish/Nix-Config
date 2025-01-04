-- Flash enhances the built-in search functionality by showing labels
-- at the end of each match, letting you quickly jump to a specific
-- location.
return {
   'folke/flash.nvim',
   event = 'VeryLazy',
   vscode = false,
   opts = {
      -- labels = "abcdefghijklmnopqrstuvwxyz",
      labels = 'asdfghjklqwertyuiopzxcvbnm',
      search = {
         -- search/jump in all windows
         multi_window = true,
         -- search direction
         forward = true,
         -- when `false`, find only matches in the given direction
         wrap = true,
         -- Each mode will take ignorecase and smartcase into account.
         -- * exact: exact match
         -- * search: regular search
         -- * fuzzy: fuzzy search
         -- * fun(str): custom function that returns a pattern
         --   For example, to only match at the beginning of a word:
         --   mode = function(str)
         --     return "\\<" .. str
         --   end,
         mode = 'exact',
         -- behave like `incsearch`
         incremental = false,
         -- Excluded filetypes and custom window filters
         exclude = {
            'notify',
            'cmp_menu',
            'noice',
            'flash_prompt',
            function(win)
               -- exclude non-focusable windows
               return not vim.api.nvim_win_get_config(win).focusable
            end,
         },
      },
      modes = {
         char = {
            enabled = true,
            -- dynamic configuration for ftFT motions
            config = function(opts)
               -- autohide flash when in operator-pending mode
               opts.autohide = opts.autohide or (vim.fn.mode(true):find 'no' and vim.v.operator == 'y')

               -- disable jump labels when not enabled, when using a count,
               -- or when recording/executing registers
               opts.jump_labels = opts.jump_labels and vim.v.count == 0 and vim.fn.reg_executing() == '' and vim.fn.reg_recording() == ''

               -- Show jump labels only in operator-pending mode
               -- opts.jump_labels = vim.v.count == 0 and vim.fn.mode(true):find("o")
            end,
            -- hide after jump when not using jump labels
            autohide = false,
            -- show jump labels
            jump_labels = false,
            -- set to `false` to use the current line only
            multi_line = true,
            -- When using jump labels, don't use these keys
            -- This allows using those keys directly after the motion
            label = { exclude = 'hjkliardc' },
            -- by default all keymaps are enabled, but you can disable some of them,
            -- by removing them from the list.
            -- If you rather use another key, you can map them
            -- to something else, e.g., { [";"] = "L", [","] = H }
            keys = { 'f', 'F', 't', 'T', [';'] = '<C-n>', [','] = '<C-p>' },
            ---@alias Flash.CharActions table<string, "next" | "prev" | "right" | "left">
            -- The direction for `prev` and `next` is determined by the motion.
            -- `left` and `right` are always left and right.
            char_actions = function(motion)
               return {
                  [';'] = 'right', -- set to `right` to always go right (otherwise "next")
                  [','] = 'left', -- set to `left` to always go left (otherwise "prev")
                  -- clever-f style
                  [motion:lower()] = 'next',
                  [motion:upper()] = 'prev',
                  -- jump2d style: same case goes next, opposite case goes prev
                  -- [motion] = "next",
                  -- [motion:match("%l") and motion:upper() or motion:lower()] = "prev",
               }
            end,
            search = { wrap = true },
            highlight = { backdrop = true },
            jump = { register = false },
         },
      },
   },
   -- stylua: ignore
   keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S",     mode = { "n", "o", "x" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
   },
}
