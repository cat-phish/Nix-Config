return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    {
      'williamboman/mason.nvim',
      -- NOTE: nixCats: use lazyAdd to only enable mason if nix wasnt involved.
      -- because we will be using nix to download things instead.
      enabled = require('nixCatsUtils').lazyAdd(true, false),
      config = true,
    }, -- NOTE: Must be loaded before dependants
    {
      'williamboman/mason-lspconfig.nvim',
      -- NOTE: nixCats: use lazyAdd to only enable mason if nix wasnt involved.
      -- because we will be using nix to download things instead.
      enabled = require('nixCatsUtils').lazyAdd(true, false),
    },
    {
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      -- NOTE: nixCats: use lazyAdd to only enable mason if nix wasnt involved.
      -- because we will be using nix to download things instead.
      enabled = require('nixCatsUtils').lazyAdd(true, false),
    },
    -- TODO: check josean martinez video on how to implement this fileoperations plugin
    -- TODO: nixCats: paclage doesn't exist
    { 'antosha417/nvim-lsp-file-operations', config = true },

    -- Useful status updates for LSP.
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by nvim-cmp
    'hrsh7th/cmp-nvim-lsp',
    -- Adds features for coding in Neovim with Lua
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          -- adds type hints for nixCats global
          { path = (require('nixCats').nixCatsPath or '') .. '/lua', words = { 'nixCats' } },
        },
      },
      config = true,
    },
    -- Adds language features for kmonad files
    {
      'kmonad/kmonad-vim',
      ft = 'kdb',
    },
    -- Adds language features for autohotkey files
    -- TODO: nixCats: package doesn't exist
    {
      'DasGandlaf/nvim-autohotkey',
    },
    {
      -- TODO: expand on this setup and look into nvim-cmp integration

      -- TODO: nixCats: check if conditional is needed for this plugin
      'p00f/clangd_extensions.nvim',
      lazy = true,
      config = function() end,
      opts = {
        inlay_hints = {
          inline = false,
        },
        ast = {
          --These require codicons (https://github.com/microsoft/vscode-codicons)
          role_icons = {
            type = '',
            declaration = '',
            expression = '',
            specifier = '',
            statement = '',
            ['template argument'] = '',
          },
          kind_icons = {
            Compound = '',
            Recovery = '',
            TranslationUnit = '',
            PackExpansion = '',
            TemplateTypeParm = '',
            TemplateTemplateParm = '',
            TemplateParamObject = '',
          },
        },
      },
    },
  },
  config = function()
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end
        require('clangd_extensions.inlay_hints').setup_autocmd()
        require('clangd_extensions.inlay_hints').set_inlay_hints()
        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        map('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')

        -- Find references for the word under your cursor.
        map('gr', require('telescope.builtin').lsp_references, 'Goto References')

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map('gI', require('telescope.builtin').lsp_implementations, 'Goto Implementation')

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map('<leader>ct', require('telescope.builtin').lsp_type_definitions, 'Type Definition')

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map('<leader>cs', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map('<leader>cS', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<leader>cr', vim.lsp.buf.rename, 'Rename')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('gD', vim.lsp.buf.declaration, 'Goto Declaration')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- Change diagnostic symbols in the sign column (gutter)
    if vim.g.have_nerd_font then
      local signs = { ERROR = ' ', WARN = ' ', INFO = ' ', HINT = '' }
      local diagnostic_signs = {}
      for type, icon in pairs(signs) do
        diagnostic_signs[vim.diagnostic.severity[type]] = icon
      end
      vim.diagnostic.config { signs = { text = diagnostic_signs } }
    end

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    --
    -- See here for an organized list of available LSPs
    -- https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#available-lsp-servers
    -- NOTE: nixCats: there is help in nixCats for lsps at `:h nixCats.LSPs` and also `:h nixCats.luaUtils`
    local servers = {}
    -- servers.clangd = {},
    -- servers.gopls = {},
    -- servers.pyright = {},
    -- servers.rust_analyzer = {},
    -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`tsserver`) will work just fine
    -- servers.tsserver = {},
    --

    -- NOTE: nixCats: nixd is not available on mason.
    if require('nixCatsUtils').isNixCats then
      servers.nixd = {}
    else
      servers.rnix = {}
      servers.nil_ls = {}
    end
    servers.bashls = { -- Bash
      bashIde = {
        globPattern = '*@(.sh|.inc|.bash|.command)',
      },
    }
    servers.clangd = { -- C/C++
      keys = {
        { '<leader>cR', '<cmd>ClangdSwitchSourceHeader<cr>', desc = 'Switch Source/Header (C/C++)' },
      },
      root_dir = function(fname)
        return require('lspconfig.util').root_pattern(
          '.clangd',
          '.clang-tidy',
          '.clang-format',
          'compile_commands.json',
          'compile_flags.txt',
          'configure.ac' -- AutoTools
        )(fname) or vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
      end,
      capabilities = {
        offsetEncoding = { 'utf-16' },
      },
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
    }
    serves.eslint = {} -- Javascript
    servers.html = {}
    servers.jsonls = {} -- JSON
    servers.lua_ls = {
      -- cmd = {...},
      -- filetypes = { ...},
      -- capabilities = {},
      settings = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
          diagnostics = {
            globals = { 'nixCats' },
            disable = { 'missing-fields' },
          },
        },
      },
    }
    servers.marksman = {} -- Markdown
    servers.rnix = {} -- Nix
    servers.pyright = {} -- Python
    servers.rust_analyzer = {} -- Rust
    servers.tailwindcss = { -- CSS
      classAttributes = { 'class', 'className', 'class:list', 'classList', 'ngClass' },
      includeLanguages = {
        eelixir = 'html-eex',
        eruby = 'erb',
        htmlangular = 'html',
        templ = 'html',
      },
      lint = {
        cssConflict = 'warning',
        invalidApply = 'error',
        invalidConfigPath = 'error',
        invalidScreen = 'error',
        invalidTailwindDirective = 'error',
        invalidVariant = 'error',
        recommendedVariantOrder = 'warning',
      },
      validate = true,
    }
    servers.typos_lsp = {}

    -- NOTE: nixCats: if nix, use lspconfig instead of mason
    -- You could MAKE it work, using lspsAndRuntimeDeps and sharedLibraries in nixCats
    -- but don't... its not worth it. Just add the lsp to lspsAndRuntimeDeps.
    if require('nixCatsUtils').isNixCats then
      for server_name, _ in pairs(servers) do
        require('lspconfig')[server_name].setup {
          capabilities = capabilities,
          settings = servers[server_name],
          filetypes = (servers[server_name] or {}).filetypes,
          cmd = (servers[server_name] or {}).cmd,
          root_pattern = (servers[server_name] or {}).root_pattern,
        }
      end
    else
      -- [[ Mason Setup ]]
      -- if not Nix setup mason normally
      require('mason').setup {
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      }
      -- Set up keybinding for Mason
      vim.keymap.set('n', '<leader>pm', '<cmd>Mason<cr>', { desc = 'Mason' })

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'beautysh', -- Bash formatter
        'black', -- Python formatter
        'codelldb', -- C++ debugger
        'clang-format', -- C/C++ formatter
        'cpplint', -- C++ Linter
        'eslint_d', -- JS Linter
        'isort', -- Python import formatter
        'markdownlint', -- Markdown linter
        'nixpkgs-fmt', -- Nix formatter
        'prettier', -- Prettier formatter for JS, Markdown, JSON, HTML, CSS, and more
        'prettierd', -- JS formatter
        'pylint', -- Python Linter
        'stylua', -- Lua formatter
        'vint', -- Vimscript Linter
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end
  end,
}
