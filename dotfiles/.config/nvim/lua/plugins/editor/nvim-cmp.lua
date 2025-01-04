-- auto completion
return {
  'hrsh7th/nvim-cmp',
  version = false, -- last release is way too old
  event = 'InsertEnter',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    {
      'L3MON4D3/LuaSnip',
      -- follow latest release.
      version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = 'make install_jsregexp',
    }, -- Snippet Engine & its associated nvim-cmp source
    {
      'L3MON4D3/LuaSnip',
      -- NOTE: nixCats: nix downloads it with a different file name.
      -- tell lazy about that.
      name = 'luasnip',
      -- follow latest release.
      version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      build = require('nixCatsUtils').lazyAdd((function()
        -- Build Step is needed for regex support in snippets.
        -- This step is not supported in many windows environments.
        -- Remove the below condition to re-enable on windows.
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)()),
      dependencies = {
        -- `friendly-snippets` contains a variety of premade snippets.
        --    See the README about individual language/framework/plugin snippets:
        --    https://github.com/rafamadriz/friendly-snippets
        -- {
        --   'rafamadriz/friendly-snippets',
        --   config = function()
        --     require('luasnip.loaders.from_vscode').lazy_load()
        --   end,
        -- },
      },
    },
    'saadparwaiz1/cmp_luasnip', -- for autocompletion
    'rafamadriz/friendly-snippets', -- useful snippets
    'onsails/lspkind.nvim', -- vs-code like pictograms
  },
  opts = function()
    vim.api.nvim_set_hl(0, 'CmpGhostText', { link = 'Comment', default = true })
    local cmp = require 'cmp'
    local defaults = require 'cmp.config.default'()
    local luasnip = require 'luasnip'
    local lspkind = require 'lspkind' -- TODO: figure out why this was included, unused
    return {
      completion = {
        completeopt = 'menu,menuone,noinsert,noselect',
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      -- preselect = cmp.PreselectMode.None(),
      mapping = cmp.mapping.preset.insert {
        -- These mappings disable the Up/Down arrow keys for suggestions and kills the suggestion box
        ['<Down>'] = cmp.mapping(function(fallback)
          cmp.close()
          fallback()
        end, { 'i' }),
        ['<Up>'] = cmp.mapping(function(fallback)
          cmp.close()
          fallback()
        end, { 'i' }),
        -- These mappings are for interacting with the selections
        ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
        ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
        ['<C-e>'] = cmp.mapping.abort(),
        -- Unused mappings, svaed for the future, maybe...
        -- ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        -- ["<C-f>"] = cmp.mapping.scroll_docs(4),
        -- ["<C-Space>"] = cmp.mapping.complete(),
        -- ["<C-CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        -- ["<C-M-CR>"] = cmp.mapping.confirm({
        --    behavior = cmp.ConfirmBehavior.Replace,
        --    select = false,
        -- }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        -- ["<C-CR>"] = function(fallback)
        -- 	cmp.abort()
        -- 	fallback()
        -- end,
      },
      sources = cmp.config.sources {
        {
          name = 'lazydev',
          group_index = 0, -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
        },
        { name = 'nvim_lsp' },
        { name = 'buffer' }, -- text within current buffer
        { name = 'path' }, -- file system paths
        { name = 'luasnip' }, -- snippets
      },
      formatting = {
        format = function(_, item)
          local icons = require('config.icons').icons.kinds
          if icons[item.kind] then
            item.kind = icons[item.kind] .. item.kind
          end
          return item
        end,
      },
      experimental = {
        ghost_text = {
          hl_group = 'CmpGhostText',
        },
      },
      sorting = defaults.sorting,
    }
  end,
  config = function(_, opts)
    for _, source in ipairs(opts.sources) do
      source.group_index = source.group_index or 1
    end
    require('cmp').setup(opts)
  end,
}
