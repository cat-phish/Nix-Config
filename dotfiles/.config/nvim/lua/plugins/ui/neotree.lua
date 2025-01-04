return {
   'nvim-neo-tree/neo-tree.nvim',
   branch = 'v3.x',
   cmd = 'Neotree',
   dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
   },
   keys = {
      {
         '<leader>ue',
         function()
            require('neo-tree.command').execute { toggle = true, dir = vim.loop.cwd() }
         end,
         desc = 'Explorer NeoTree (cwd)',
      },
      { '<leader>e', '<leader>ue', desc = 'Explorer NeoTree (cwd)', remap = true },
      {
         '<leader>ge',
         function()
            require('neo-tree.command').execute { source = 'git_status', toggle = true }
         end,
         desc = 'Git explorer',
      },
      {
         '<leader>be',
         function()
            require('neo-tree.command').execute { source = 'buffers', toggle = true }
         end,
         desc = 'Buffer explorer',
      },
   },
   opts = {
      sources = { 'filesystem', 'buffers', 'git_status', 'document_symbols' },
      open_files_do_not_replace_types = { 'terminal', 'Trouble', 'trouble', 'qf', 'Outline' },
      filesystem = {
         bind_to_cwd = false,
         follow_current_file = { enabled = true },
         use_libuv_file_watcher = true,
         filtered_items = {
            visible = true,
            show_hidden_count = true,
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_by_name = {
               -- '.git',
               -- '.DS_Store',
               -- 'thumbs.db',
            },
            never_show = {},
         },
      },
      window = {
         mappings = {
            ['<space>'] = 'none',
            ['<BS>'] = 'close_node',
            ['Y'] = function(state)
               local node = state.tree:get_node()
               local path = node:get_id()
               vim.fn.setreg('+', path, 'c')
            end,
            ['<2-LeftMouse>'] = 'open',
            ['<cr>'] = 'open',
            ['<esc>'] = 'cancel', -- close preview or floating neo-tree window
            ['P'] = { 'toggle_preview', config = { use_float = true, use_image_nvim = true } },
            -- Read `# Preview Mode` for more information
            ['l'] = 'focus_preview',
            ['_'] = 'open_split',
            ['|'] = 'open_vsplit',
            ['s'] = function()
               require('flash').jump {
                  search = { forward = true, wrap = false, multi_window = false },
               }
            end,
            ['S'] = function()
               require('flash').jump {
                  search = { forward = false, wrap = false, multi_window = false },
               }
            end,
            -- ["S"] = "split_with_window_picker",
            -- ["s"] = "vsplit_with_window_picker",
            -- ['t'] = 'none',
            -- ["<cr>"] = "open_drop",
            -- ["t"] = "open_tab_drop",
            -- ['w'] = 'open_with_window_picker',
            --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
            ['C'] = 'close_node',
            -- ['C'] = 'close_all_subnodes',
            ['z'] = 'close_all_nodes',
            --["Z"] = "expand_all_nodes",
            ['a'] = {
               'add',
               -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
               -- some commands may take optional config options, see `:h neo-tree-mappings` for details
               config = {
                  show_path = 'none', -- "none", "relative", "absolute"
               },
            },
            ['A'] = 'add_directory', -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
            ['d'] = 'delete',
            ['r'] = 'rename',
            ['b'] = 'rename_basename',
            ['y'] = 'copy_to_clipboard',
            ['x'] = 'cut_to_clipboard',
            ['p'] = 'paste_from_clipboard',
            ['c'] = { -- takes text input for destination, also accepts the optional config.show_path option like "add":
               'copy',
               config = {
                  show_path = 'absolute', -- "none", "relative", "absolute"
               },
            },
            ['m'] = {
               'move', -- takes text input for destination, also accepts the optional config.show_path option like "add".
               config = {
                  show_path = 'absolute', -- "none", "relative", "absolute"
               },
            },
            ['q'] = 'close_window',
            ['R'] = 'refresh',
            ['?'] = 'show_help',
            ['<'] = 'prev_source',
            ['>'] = 'next_source',
            ['i'] = 'show_file_details',
         },
      },
      default_component_configs = {
         indent = {
            with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
            expander_collapsed = '',
            expander_expanded = '',
            expander_highlight = 'NeoTreeExpander',
         },
      },
      event_handlers = {
         {
            event = 'neo_tree_buffer_enter',
            handler = function(arg)
               vim.cmd [[
            setlocal relativenumber
            ]]
            end,
         },
      },
   },
}
