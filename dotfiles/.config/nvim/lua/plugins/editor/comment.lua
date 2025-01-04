return {
  'numToStr/Comment.nvim',
  -- NOTE: nixCats: nix downloads it with a different file name.
  -- tell lazy about that.
  name = 'comment.nvim',
  event = 'VeryLazy',
  opts = {
    ---Add a space b/w comment and the line
    padding = true,
    ---Whether the cursor should stay at its position
    sticky = true,
    ---Lines to be ignored while (un)comment
    ignore = nil,
    ---LHS of toggle mappings in NORMAL mode
    toggler = {
      ---Line-comment toggle keymap
      line = 'xx',
      ---Block-comment toggle keymap
      block = 'xb',
    },
    ---LHS of operator-pending mappings in NORMAL and VISUAL mode
    opleader = {
      ---Line-comment keymap
      line = 'xx',
      ---Block-comment keymap
      block = 'xb',
    },
    ---LHS of extra mappings
    extra = {
      ---Add comment on the line above
      above = 'xa',
      ---Add comment on the line below
      below = 'xz',
      ---Add comment at the end of line
      eol = 'xe',
    },
    ---Enable keybindings
    -- NOTE: If given `false` then the plugin won't create any mappings
    mappings = {
      ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
      basic = true,
      ---Extra mapping; `xa`, `xz`, `xe`
      extra = true,
    },
    ---Function to call before (un)comment
    pre_hook = nil,
    ---Function to call after (un)comment
    post_hook = nil, -- add any options here
  },
  lazy = false,
}
