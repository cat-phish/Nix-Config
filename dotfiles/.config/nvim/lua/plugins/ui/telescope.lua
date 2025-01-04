-- Fuzzy finder.
-- The default key bindings to find files will use Telescope's
-- `find_files` or `git_files` depending on whether the
-- directory is a git repo.
return {
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  -- event = "VeryLazy",
  version = false, -- telescope did only one release, so use HEAD for now
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      -- NOTE: nixCats: use lazyAdd to only run build steps if nix wasnt involved.
      -- because nix already did this.
      build = require('nixCatsUtils').lazyAdd 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      -- NOTE: nixCats: use lazyAdd to only add this if nix wasnt involved.
      -- because nix built it already, so who cares if we have make in the path.
      cond = require('nixCatsUtils').lazyAdd(function()
        return vim.fn.executable 'make' == 1
      end),
    },
    {
      'isak102/telescope-git-file-history.nvim',
      dependencies = {
        'tpope/vim-fugitive',
        'nvim-lua/plenary.nvim',
      },
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  keys = {
    {
      '<leader><space>',
      '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>',
      desc = 'Switch Buffer',
    },
    { '<leader>/', "<cmd>lua require'telescope.builtin'.live_grep{}<cr>", desc = 'Grep (cwd)' },
    -- files
    { '<leader>fb', '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>', desc = 'Find Buffers' },
    { '<leader>ff', "<cmd>lua require'telescope.builtin'.find_files{}<cr>", desc = 'Find Files (cwd)' },
    { '<leader>fg', '<cmd>Telescope git_files<cr>', desc = 'Find Git Files' },
    { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Find Recent Files' },
    -- git
    { '<leader>gc', '<cmd>Telescope git_commits<CR>', desc = 'Commits' },
    { '<leader>gC', '<cmd>Telescope git_file_history<CR>', desc = 'Commit History (file)' },
    { '<leader>gs', '<cmd>Telescope git_status<CR>', desc = 'Status' },
    -- search
    { '<leader>s"', '<cmd>Telescope registers<cr>', desc = 'Search Registers' },
    { '<leader>sb', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Search in Buffer' },
    { '<leader>sd', '<cmd>Telescope diagnostics bufnr=0<cr>', desc = 'Document diagnostics' },
    { '<leader>sD', '<cmd>Telescope diagnostics<cr>', desc = 'Workspace diagnostics' },
    -- { "<leader>sg",  Util.telescope("live_grep", { cwd = false }),                      desc = "Grep (cwd)" },
    -- { "<leader>sG",  Util.telescope("live_grep"),                                       desc = "Grep (root dir)" },
    { '<leader>sH', '<cmd>Telescope highlights<cr>', desc = 'Search Highlight Groups' },
    { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Jump to Mark' },
    { '<leader>sR', '<cmd>Telescope resume<cr>', desc = 'Resume' },
    { '<leader>sw', "<cmd>lua require'telescope.builtin'.grep_string{}<cr>", desc = 'Word (cwd)' },
    -- { "<leader>sW",  Util.telescope("grep_string", { word_match = "-w" }),              desc = "Word (root dir)" },
    { '<leader>sw', "<cmd>lua require'telescope.builtin'.grep_string{}<cr>", mode = 'v', desc = 'Selection (cwd)' },
    -- { "<leader>sW",  Util.telescope("grep_string"),                                     mode = "v",                      desc = "Selection (root dir)" },
    -- search neovim
    { '<leader>sn:', '<cmd>Telescope command_history<cr>', desc = 'Command History' },
    { '<leader>sna', '<cmd>Telescope autocommands<cr>', desc = 'Auto Commands' },
    { '<leader>snc', '<cmd>Telescope commands<cr>', desc = 'Commands' },
    { '<leader>snC', '<cmd>Telescope command_history<cr>', desc = 'Command History' },
    { '<leader>snh', '<cmd>Telescope help_tags<cr>', desc = 'Help Pages' },
    { '<leader>snk', '<cmd>Telescope keymaps<cr>', desc = 'Key Maps' },
    { '<leader>snM', '<cmd>Telescope man_pages<cr>', desc = 'Man Pages' },
    { '<leader>sno', '<cmd>Telescope vim_options<cr>', desc = 'Options' },
    { '<leader>uc', "<cmd>lua require'telescope.builtin'colorscheme{}<cr>", desc = 'Colorscheme with preview' },
    -- Search Colorschemes with Preview
    {
      '<leader>uc',
      function()
        require('telescope.builtin').colorscheme { enable_preview = true }
      end,
      desc = 'Colorscheme with preview',
    },
  },
  opts = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'

    -- Load extensions
    telescope.load_extension 'fzf'
    telescope.load_extension 'git_file_history'
    telescope.load_extension 'ui-select'

    local open_with_trouble = function(...)
      return require('trouble.providers.telescope').open_with_trouble(...)
    end
    local open_selected_with_trouble = function(...)
      return require('trouble.providers.telescope').open_selected_with_trouble(...)
    end
    return {
      defaults = {
        prompt_prefix = ' ',
        selection_caret = ' ',
        -- open files in the first window that is an actual file.
        -- use the current window if no other window is available.
        get_selection_window = function()
          local wins = vim.api.nvim_list_wins()
          table.insert(wins, 1, vim.api.nvim_get_current_win())
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == '' then
              return win
            end
          end
          return 0
        end,
        mappings = {
          i = {
            ['<c-t>'] = open_with_trouble,
            ['<a-t>'] = open_selected_with_trouble,
            ['<C-Down>'] = actions.cycle_history_next,
            ['<C-Up>'] = actions.cycle_history_prev,
            ['<C-f>'] = actions.preview_scrolling_down,
            ['<C-b>'] = actions.preview_scrolling_up,
          },
          n = {
            ['q'] = actions.close,
          },
        },
      },
    }
  end,
}
