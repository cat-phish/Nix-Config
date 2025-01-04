return {
   -- edgy
   {
      'folke/edgy.nvim',
      event = 'VeryLazy',
      keys = {
         -- NOTE: disabled, since I don't really use and conflicts with explorer toggle
         -- also causes strange ui flickering issues with neotree
         -- {
         -- 	"<leader>e",
         -- 	function()
         -- 		require("edgy").toggle()
         -- 	end,
         -- 	desc = "edgy toggle",
         -- },
      -- stylua: ignore
      { "<leader>fe", function() require("edgy").select() end, desc = "Find Edgy Window" },
      },
      opts = function()
         local opts = {
            bottom = {
               {
                  ft = 'toggleterm',
                  size = { height = 0.4 },
                  filter = function(buf, win)
                     return vim.api.nvim_win_get_config(win).relative == ''
                  end,
               },
               {
                  ft = 'noice',
                  size = { height = 0.4 },
                  filter = function(buf, win)
                     return vim.api.nvim_win_get_config(win).relative == ''
                  end,
               },
               -- TODO: disabled in favor of floating term due to weird screen darkening behavior
               -- {
               -- 	ft = "lazyterm",
               -- 	title = "lazyterm",
               -- 	size = { height = 0.4 },
               -- 	filter = function(buf)
               -- 		return not vim.b[buf].lazyterm_cmd
               -- 	end,
               -- },
               'trouble',
               { ft = 'qf', title = 'quickfix' },
               {
                  ft = 'trouble',
                  filter = function(buf, win)
                     return vim.api.nvim_win_get_config(win).relative == ''
                  end,
               },
               {
                  ft = 'help',
                  size = { height = 30 },
                  -- don't open help files in edgy that we're editing
                  filter = function(buf)
                     return vim.bo[buf].buftype == 'help'
                  end,
               },
               { title = 'spectre', ft = 'spectre_panel', size = { height = 0.4 } },
               { title = 'neotest output', ft = 'neotest-output-panel', size = { height = 15 } },
            },
            left = {
               {
                  title = 'neo-tree',
                  ft = 'neo-tree',
                  filter = function(buf)
                     return vim.b[buf].neo_tree_source == 'filesystem'
                  end,
                  pinned = true,
                  open = function()
                     vim.api.nvim_input '<esc><space>e'
                  end,
                  size = { height = 0.5 },
               },
               { title = 'Neotest summary', ft = 'neotest-summary' },
               {
                  title = 'neo-tree git',
                  ft = 'neo-tree',
                  filter = function(buf)
                     return vim.b[buf].neo_tree_source == 'git_status'
                  end,
                  pinned = true,
                  open = 'Neotree position=right git_status',
               },
               {
                  title = 'neo-tree buffers',
                  ft = 'neo-tree',
                  filter = function(buf)
                     return vim.b[buf].neo_tree_source == 'buffers'
                  end,
                  pinned = true,
                  open = 'Neotree position=top buffers',
               },
               'neo-tree',
            },
            keys = {
               -- increase width
               ['<c-right>'] = function(win)
                  win:resize('width', 2)
               end,
               -- decrease width
               ['<c-left>'] = function(win)
                  win:resize('width', -2)
               end,
               -- increase height
               ['<c-up>'] = function(win)
                  win:resize('height', 2)
               end,
               -- decrease height
               ['<c-down>'] = function(win)
                  win:resize('height', -2)
               end,
            },
         }
         return opts
      end,
   },

   -- use edgy's selection window
   {
      'nvim-telescope/telescope.nvim',
      optional = true,
      opts = {
         defaults = {
            get_selection_window = function()
               require('edgy').goto_main()
               return 0
            end,
         },
      },
   },

   -- prevent neo-tree from opening files in edgy windows
   {
      'nvim-neo-tree/neo-tree.nvim',
      optional = true,
      opts = function(_, opts)
         opts.open_files_do_not_replace_types = opts.open_files_do_not_replace_types or { 'terminal', 'trouble', 'qf', 'outline', 'trouble' }
         table.insert(opts.open_files_do_not_replace_types, 'edgy')
      end,
   },

   -- fix bufferline offsets when edgy is loaded
   {
      'akinsho/bufferline.nvim',
      optional = true,
      opts = function()
         local offset = require 'bufferline.offset'
         if not offset.edgy then
            local get = offset.get
            offset.get = function()
               if package.loaded.edgy then
                  local layout = require('edgy.config').layout
                  local ret = { left = '', left_size = 0, right = '', right_size = 0 }
                  for _, pos in ipairs { 'left', 'right' } do
                     local sb = layout[pos]
                     if sb and #sb.wins > 0 then
                        local title = ' sidebar' .. string.rep(' ', sb.bounds.width - 8)
                        ret[pos] = '%#edgytitle#' .. title .. '%*' .. '%#winseparator#│%*'
                        ret[pos .. '_size'] = sb.bounds.width
                     end
                  end
                  ret.total_size = ret.left_size + ret.right_size
                  if ret.total_size > 0 then
                     return ret
                  end
               end
               return get()
            end
            offset.edgy = true
         end
      end,
   },
}
