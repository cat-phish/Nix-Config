-- install with yarn or npm
-- return {
--    "iamcco/markdown-preview.nvim",
--    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
--    build = "cd app && yarn install",
--    init = function()
--       vim.g.mkdp_filetypes = { "markdown" }
--    end,
--    ft = { "markdown" },
-- }

-- install without yarn or npm
return {
   'iamcco/markdown-preview.nvim',
   event = 'VeryLazy',
   cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
   ft = { 'markdown' },
   build = function()
      vim.fn['mkdp#util#install']()
   end,
   keys = {
      {
         '<leader>um',
         ft = 'markdown',
         '<cmd>MarkdownPreviewToggle<cr>',
         desc = 'Markdown Preview',
      },
   },
   config = function()
      vim.cmd [[do FileType]]
      vim.cmd [[
         function OpenMarkdownPreview (url)
            let cmd = "google-chrome-stable --new-window " . shellescape(a:url) . " &"
            silent call system(cmd)
         endfunction
      ]]
      vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'
   end,
}
