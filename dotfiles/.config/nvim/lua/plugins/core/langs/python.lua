return {
  -- Add Python to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "python" })
      end
    end,
  },
  -- Add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          -- Add any pyright-specific settings here
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "strict",
              },
            },
          },
        },
      },
    },
  },
}
