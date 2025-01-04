return {
   'code-biscuits/nvim-biscuits',
   event = 'VeryLazy',
   config = function()
      require('nvim-biscuits').setup {
         -- toggle_keybind = "<leader>Eb",
         default_config = {
            cursor_line_only = true,
            max_length = 10,
            trim_by_words = true,
            min_distance = 5,
            -- prefix_string = "🍪",
            prefix_string = '  🐒',
         },
         language_config = {
            help = {
               disabled = true,
            },
            vimdoc = {
               disabled = true,
            },
         },
      }
   end,
}
