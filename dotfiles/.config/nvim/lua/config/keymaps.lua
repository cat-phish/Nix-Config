-- TODO: go through whole config and make sure to add all mappings as comments here

local Util = require 'config.utils'

-- [[ Navigation Maps ]]

-- Beginning and End of Line
local function jump_to_line_start()
   -- If cursor is at the first non-blank character, jump to the beginning of the line
   -- Otherwise, jump to the first non-blank character
   local col = vim.fn.col '.'
   local first_non_blank = vim.fn.indent(vim.fn.line '.') + 1
   if col == first_non_blank then
      vim.cmd 'normal! 0'
   else
      vim.cmd 'normal! ^'
   end
end
vim.keymap.set({ 'n', 'v' }, 'H', jump_to_line_start, { noremap = true, desc = 'Beginning of line' })
-- vim.keymap.set({ 'n', 'v' }, 'H', '^', { desc = 'Beginning of Line' })
vim.keymap.set({ 'n', 'v' }, 'L', '$', { desc = 'End of Line' })

-- better up/down
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Saner behavior of n and N
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
vim.keymap.set('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
vim.keymap.set('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
vim.keymap.set('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
vim.keymap.set('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
vim.keymap.set('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })

-- Vim-Illuminate
-- NOTE: below mapped in plugins/editor/vim-illuminate.lua
-- { "]]", desc = "Next Reference" },
-- { "[[", desc = "Prev Reference" },

-- [[ General Text Editing Maps ]]

-- Caps Lock
-- NOTE: below mapped in plugins/editor/capslock.lua
-- keys = {
--    { "<C-a>", "<Plug>CapsLockToggle", mode = {"n", "i", "c"}, desc = "CapsLock Toggle" }
-- }

-- save file
vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save file' })

-- better indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Don't yank on dd on empty line
vim.keymap.set('n', 'dd', function()
   if vim.api.nvim_get_current_line():find '^%s*$' then
      return '"_dd'
   end
   return 'dd'
end, { expr = true })

-- Delete with C-l in insert to mirror default C-h backspace
vim.keymap.set('i', '<C-l>', '<Del>', { desc = 'Delete' })

-- Move Lines
vim.keymap.set('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move up' })
-- The mappings below are disabled because escaping to Normal mode and
-- pressing j or k too quickly can cause lines to shift. Also, it's
-- unnecessary to use these mappings when the above mappings are available.
-- vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
-- vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })

-- Easier redo
-- vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

-- Quick Macro
vim.keymap.set('n', 'Q', '@q', { desc = 'Quick Macro' })

-- Remap tab in cmdline to complete (not working, but it does disable tab insertion)
vim.keymap.set('c', '<Tab>', '<C-n>', { noremap = true })

-- Commenting
-- NOTE: below mapped in plugins/editor/comment.lua
-- toggler = {
--    ---Line-comment toggle keymap
--    line = "xx",
--    ---Block-comment toggle keymap
--    block = "xb",
-- },
-- ---LHS of operator-pending mappings in NORMAL and VISUAL mode
-- opleader = {
--    ---Line-comment keymap
--    line = "xx",
--    ---Block-comment keymap
--    block = "xb",
-- },
-- ---LHS of extra mappings
-- extra = {
--    ---Add comment on the line above
--    above = "xa",
--    ---Add comment on the line below
--    below = "xz",
--    ---Add comment at the end of line
--    eol = "xe",
-- },

-- Auto-Pairs
-- NOTE: this mapping is dependent on plugins/editor/mini-pairs.lua
vim.keymap.set('n', '<leader>op', function()
   vim.g.minipairs_disable = not vim.g.minipairs_disable
   if vim.g.minipairs_disable then
      Util.warn('Disabled auto pairs', { title = 'Option' })
   else
      Util.info('Enabled auto pairs', { title = 'Option' })
   end
end, { desc = 'Toggle auto pairs' })

-- Replace in Multiple Files (Spectre)
-- NOTE: below mapped in plugins/editor/nvim-spectre.lua
-- { "<leader>sr", function() require("spectre").open() end, desc = "Replace in Multiple Files" },

-- Yanky
-- NOTE: below mapped in plugins/editor/yanky.lua
-- { "<leader>snp", function() require("telescope").extensions.yank_history.yank_history({ }) end, desc = "Open Yank History" },
-- { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
-- { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after cursor" },
-- { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
-- { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
-- { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
-- { "[y", "<Plug>(YankyCycleForward)", desc = "Cycle forward through yank history" },
-- { "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle backward through yank history" },
-- { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
-- { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
-- { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
-- { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
-- { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and indent right" },
-- { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and indent left" },
-- { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and indent right" },
-- { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and indent left" },
-- { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after applying a filter" },
-- { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before applying a filter" },

-- Toggle Spelling
vim.keymap.set('n', '<leader>os', function()
   vim.wo.spell = not vim.wo.spell
   if vim.wo.spell then
      Util.info('Enabled spelling', { title = 'Option' })
   else
      Util.warn('Disabled spelling', { title = 'Option' })
   end
end, { desc = 'Toggle Spelling' })

--#################
--####  Coding ####
--#################

-- Completion with Auto-Insert
-- NOTE: below mapped in plugins/editor/nvim-cmp.lua
-- ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
-- ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),

-- Format Buffer
-- NOTE: below mapped in plugins/core/formatting.lua
-- {
--    '<leader>cf',
--    function()
--       require('conform').format { async = true, lsp_format = 'fallback' }
--    end,
--    mode = '',
--    desc = 'Format buffer',
-- },

-- Quickfix
vim.keymap.set('n', '<leader>Dl', '<cmd>lopen<cr>', { desc = 'Location List' })
vim.keymap.set('n', '<leader>Dq', '<cmd>copen<cr>', { desc = 'Quickfix List' })
vim.keymap.set('n', '[q', vim.cmd.cprev, { desc = 'Previous quickfix' })
vim.keymap.set('n', ']q', vim.cmd.cnext, { desc = 'Next quickfix' })

-- Copilot Toggle
vim.keymap.set('n', '<leader>cpe', '<cmd>Copilot enable<CR>', { desc = 'Copilot Suggestions Enable' })
vim.keymap.set('n', '<leader>cpd', '<cmd>Copilot disable<CR>', { desc = 'Copilot Suggestions Disable' })

-- Copilot Completion
-- NOTE: below mapped in plugins/editor/copilot.lua
-- panel = {
--    jump_prev = "[[",
--    jump_next = "]]",
--    accept = "<CR>",
--    refresh = "gr",
--    open = "<M-BS>",
-- },
-- suggestion = {
--    keymap = {
--       accept = "<M-CR>",
--       next = "<M-n>",
--       prev = "<M-p>",
--       dismiss = "<M-e>",
--    },

-- diagnostic
local diagnostic_goto = function(next, severity)
   local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
   severity = severity and vim.diagnostic.severity[severity] or nil
   return function()
      go { severity = severity }
   end
end
vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })

-- toggle options
-- TODO: fix these Util calls
-- vim.keymap.set("n", "<leader>Ef", function()
-- 	Util.format.toggle()
-- end, { desc = "Toggle auto format (global)" })
-- vim.keymap.set("n", "<leader>EF", function()
-- 	Util.format.toggle(true)
-- end, { desc = "Toggle auto format (buffer)" })
-- vim.keymap.set("n", "<leader>Es", function()
-- 	Util.toggle("spell")
-- end, { desc = "Toggle Spelling" })
-- vim.keymap.set("n", "<leader>Ew", function()
-- 	Util.toggle("wrap")
-- end, { desc = "Toggle Word Wrap" })

-- vim.keymap.set("n", "<leader>Ed", function()
-- 	Util.toggle.diagnostics()
-- end, { desc = "Toggle Diagnostics" })
-- local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
-- vim.keymap.set("n", "<leader>Ec", function()
-- 	Util.toggle("conceallevel", false, { 0, conceallevel })
-- end, { desc = "Toggle Conceal" })
-- if vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint then
-- 	vim.keymap.set("n", "<leader>Eh", function()
-- 		Util.toggle.inlay_hints()
-- 	end,>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
-- { "'", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
-- { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
-- { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },

-- Last Buffer
vim.keymap.set('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Last buffer' })
vim.keymap.set('n', '<leader><space>', '<cmd>e #<cr>', { desc = 'Last buffer' })
vim.keymap.set('n', '<leader>`', '<cmd>e #<cr>', { desc = 'Last buffer' })

-- Move Buffer Left/Right
-- NOTE: below mapped in core/bufferline.lua
-- { "<leader>b>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
-- { "<leader>b<", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },

-- Toggle Buffer Pin
-- NOTE: below mapped in core/bufferline.lua
-- { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },

-- Delete Buffers
-- NOTE: below mapped in plugins/editor/mimi-bufremove.lua
-- { "<leader>bd", desc = "Delete Buffer", },
-- { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },

-- Delete Multiple Buffers
-- NOTE: below mapped in core/bufferline.lua
-- { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
-- { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
-- { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
-- { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },

--###################
--####  Windows  ####
--###################

-- Move to window using the <ctrl> hjkl keys
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Go to left window', remap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Go to lower window', remap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Go to upper window', remap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Go to right window', remap = true })

-- Switch to Last Window
vim.keymap.set('n', '<leader>ww', '<C-W>p', { desc = 'Last window', remap = true })
vim.keymap.set('n', '<leader>wd', '<C-W>c', { desc = 'Delete window', remap = true })

-- Window Splitting
vim.keymap.set('n', '<leader>w-', '<C-W>s', { desc = 'Split below', remap = true })
vim.keymap.set('n', '<leader>w|', '<C-W>v', { desc = 'Split right', remap = true })

-- Resize window using <ctrl> arrow keys
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

-- Windows.nvim Window Maximizer
-- NOTE: the following are mapped in plugins/ui/windows.lua
-- vim.keymap.set('n', '<leader>wm', '<cmd>WindowsMaximize<CR>', { desc = 'Maximize window' })
-- vim.keymap.set('n', '<leader>wh', '<cmd>WindowsMaximizeHorizontally<CR>', { desc = 'Maximize window (H)' })
-- vim.keymap.set('n', '<leader>wv', '<cmd>WindowsMaximizeVertically<CR>', { desc = 'Maximize window (V)' })
-- vim.keymap.set('n', '<leader>w=', '<cmd>WindowsEqualize<CR>', { desc = 'Equalize windows' })

-- Zen Mode
vim.keymap.set('n', '<leader>wz', '<cmd>ZenMode<CR>', { desc = 'Zen Mode' })

--##################
--####  Search  ####
--##################

-- Search TODO Comments
-- -- NOTE: below mapped in plugins/editor/todo-comments.lua
-- { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
-- { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
-- { "<leader>Dt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
-- { "<leader>DT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
-- { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
-- { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },

-- Find Edgy Window
-- NOTE: below mapped in plugins/ui/edgy.lua
-- { "<leader>fe", function() require("edgy").select() end, desc = "Find Edgy Window" },

-- Noice Search
-- NOTE: below mapped in plugins/ui/noice.lua
-- { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
-- { "<leader>sNl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
-- { "<leader>sNh", function() require("noice").cmd("history") end, desc = "Noice History" },
-- { "<leader>sNa", function() require("noice").cmd("all") end, desc = "Noice All" },
-- { "<leader>sNd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },

-- Search Projects
-- NOTE: below mapped in plugins/ui/project.lua
-- { "<leader>fp", "<Cmd>Telescope projects<CR>", desc = "Projects" },

--#####################
--####  Telescope  ####
--#####################

-- NOTE: below mapped in plugins/core/telescope.lua
-- { "<leader><space>", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Switch Buffer", },
-- { "<leader>/",   Util.telescope("live_grep"),                                       desc = "Grep (root dir)" },
-- { "<leader>:",   "<cmd>Telescope command_history<cr>",                              desc = "Command History" },
-- -- { "<leader><space>", Util.telescope("files"), desc = "Find Files (root dir)" },
-- -- Find
-- { "<leader>fb",  "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",     desc = "Buffers" },
-- { "<leader>fc",  Util.telescope.config_files(),                                     desc = "Find Config File" },
-- { "<leader>ff",  Util.telescope("files", { cwd = false }),                          desc = "Find Files (cwd)" },
-- { "<leader>fF",  Util.telescope("files"),                                           desc = "Find Files (root dir)" },
-- { "<leader>fg",  "<cmd>Telescope git_files<cr>",                                    desc = "Find Files (git-files)" },
-- { "<leader>fr",  Util.telescope("oldfiles", { cwd = vim.loop.cwd() }),              desc = "Recent (cwd)" },
-- { "<leader>fR",  "<cmd>Telescope oldfiles<cr>",                                     desc = "Recent" },
-- -- Git
-- { "<leader>gc",  "<cmd>Telescope git_commits<CR>",                                  desc = "commits" },
-- { "<leader>gC",  "<cmd>Telescope git_file_history<CR>",                             desc = "commit history (file)" },
-- { "<leader>gs",  "<cmd>Telescope git_status<CR>",                                   desc = "status" },

-- NOTE: below mapped in plugins/core/telescope.lua
-- -- Search
-- { '<leader>s"',  "<cmd>Telescope registers<cr>",                                    desc = "Registers" },
-- { "<leader>sb",  "<cmd>Telescope current_buffer_fuzzy_find<cr>",                    desc = "Search in Buffer" },
-- { "<leader>sd",  "<cmd>Telescope diagnostics bufnr=0<cr>",                          desc = "Document diagnostics" },
-- { "<leader>sD",  "<cmd>Telescope diagnostics<cr>",                                  desc = "Workspace diagnostics" },
-- { "<leader>sg",  Util.telescope("live_grep", { cwd = false }),                      desc = "Grep (cwd)" },
-- { "<leader>sG",  Util.telescope("live_grep"),                                       desc = "Grep (root dir)" },
-- { "<leader>sH",  "<cmd>Telescope highlights<cr>",                                   desc = "Search Highlight Groups" },
-- { "<leader>sm",  "<cmd>Telescope marks<cr>",                                        desc = "Jump to Mark" },
-- { "<leader>sr",  "<cmd>Telescope resume<cr>",                                       desc = "Resume" },
-- { "<leader>sw",  Util.telescope("grep_string", { cwd = false, word_match = "-w" }), desc = "Word (cwd)" },
-- { "<leader>sW",  Util.telescope("grep_string", { word_match = "-w" }),              desc = "Word (root dir)" },
-- { "<leader>sw",  Util.telescope("grep_string", { cwd = false }),                    mode = "v", desc = "Selection (cwd)" },
-- { "<leader>sW",  Util.telescope("grep_string"),                                     mode = "v", desc = "Selection (root dir)" },
-- -- Search Neovim
-- { "<leader>sna", "<cmd>Telescope autocommands<cr>",                                 desc = "Auto Commands" },
-- { "<leader>snc", "<cmd>Telescope commands<cr>",                                     desc = "Commands" },
-- { "<leader>snC", "<cmd>Telescope command_history<cr>",                              desc = "Command History" },
-- { "<leader>snh", "<cmd>Telescope help_tags<cr>",                                    desc = "Help Pages" },
-- { "<leader>snk", "<cmd>Telescope keymaps<cr>",                                      desc = "Key Maps" },
-- { "<leader>snM", "<cmd>Telescope man_pages<cr>",                                    desc = "Man Pages" },
-- { "<leader>sno", "<cmd>Telescope vim_options<cr>",                                  desc = "Options" },

-- NOTE: below mapped in plugins/ui/telescope.lua
-- -- search colorschemes
-- { "<leader>uc", Util.telescope("colorscheme", { enable_preview = true }), desc = "Colorscheme with preview", },
-- -- Go to Symbol
-- { "<leader>ss", function()
--       require("telescope.builtin").lsp_document_symbols({
--          symbols = require("config").get_kind_filter(),
--       })
--    end, desc = "Goto Symbol",
-- },
-- -- Go to Symbol (Workspace)
-- { "<leader>sS", function()
--       require("telescope.builtin").lsp_dynamic_workspace_symbols({
--          symbols = require("config").get_kind_filter(),
--       })
--    end, desc = "Goto Symbol (Workspace)",
-- },
-- Telescope Actions
-- i = {
--    ["<c-t>"] = open_with_trouble,
--    ["<a-t>"] = open_selected_with_trouble,
--    ["<a-i>"] = find_files_no_ignore,
--    ["<a-h>"] = find_files_with_hidden,
--    ["<C-Down>"] = actions.cycle_history_next,
--    ["<C-Up>"] = actions.cycle_history_prev,
--    ["<C-f>"] = actions.preview_scrolling_down,
--    ["<C-b>"] = actions.preview_scrolling_up,
-- },
-- n = { ["q"] = actions.close, },
-- Flash in Telescope
-- mappings = { n = { s = flash }, i = { ["<c-s>"] = flash } },

--#######################
--####  Diagnostics  ####
--#######################

-- Trouble
-- NOTE: below mapped in plugins/editor/trouble.lua
-- { "<leader>Dx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
-- { "<leader>DX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
-- { "<leader>DL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
-- { "<leader>DQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
-- { "[q", desc = "Previous trouble/quickfix item", },
-- { "]q", desc = "Next trouble/quickfix item", },

--###############
--####  Git  ####
--###############

-- lazygit
-- TODO: fix this Util call
-- vim.keymap.set("n", "<leader>gg", function()
-- 	Util.terminal({ "lazygit" }, { cwd = Util.root(), esc_esc = false, ctrl_hjkl = false })
-- end, { desc = "Lazygit (root dir)" })
-- vim.keymap.set("n", "<leader>gG", function()
-- 	Util.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false })
-- end, { desc = "Lazygit (cwd)" })

-- Git-Signs
-- NOTE: below mapped in plugins/editor/gitsigns.lua
-- vim.keymap.set("n", "]h", gs.next_hunk, "Next Hunk")
-- vim.keymap.set("n", "[h", gs.prev_hunk, "Prev Hunk")
-- vim.keymap.set({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
-- vim.keymap.set({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
-- vim.keymap.set("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
-- vim.keymap.set("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
-- vim.keymap.set("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
-- vim.keymap.set("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
-- vim.keymap.set("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
-- vim.keymap.set("n", "<leader>ghd", gs.diffthis, "Diff This")
-- vim.keymap.set("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
-- vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")

--##############
--####  UI  ####
--##############

-- quit
vim.keymap.set('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })

-- Dismiss Notifications
-- NOTE: below mapped in plugins/ui/notify.lua
-- { "<leader>un", desc = "Dismiss all Notifications", },

-- Flag to track temporary toggle state
local temp_relnu_toggle = false

-- Permanent Toggle Relative Line Numbers
vim.keymap.set('n', '<leader>on', function()
   if vim.opt_local.relativenumber:get() then
      -- Switch to static line numbers
      vim.opt_local.relativenumber = false
      Util.info('Switched to absolute line numbers', { title = 'Option' })
   else
      -- Switch to relative line numbers
      vim.opt_local.relativenumber = true
      Util.info('Switched to relative line numbers', { title = 'Option' })
   end
end, { desc = 'Toggle relative/absolute line numbers' })

-- Temporary Toggle Relative Line Numbers
vim.keymap.set('n', '<leader>n', function()
   if vim.opt_local.relativenumber:get() then
      -- Switch to static line numbers
      vim.opt_local.relativenumber = false
      temp_relnu_toggle = true
      Util.info('Temporarily switched to absolute line numbers', { title = 'Option' })
   else
      -- Switch to relative line numbers
      vim.opt_local.relativenumber = true
      temp_relnu_toggle = false
      Util.info('Switched to relative line numbers', { title = 'Option' })
   end
end, { desc = 'Temp Toggle Rel/Abs Line Numbers' })
-- Autocommand to re-enable relative line numbers if they were temporarily turned off
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave' }, {
   callback = function()
      if temp_relnu_toggle and not vim.opt_local.relativenumber:get() then
         vim.opt_local.relativenumber = true
         Util.info('Re-enabled relative line numbers', { title = 'Option' })
         temp_relnu_toggle = false
      end
   end,
})

-- Toggle Line Number Visibility
vim.keymap.set('n', '<leader>oN', function()
   if vim.opt_local.number:get() or vim.opt_local.relativenumber:get() then
      nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      Util.warn('Disabled line numbers', { title = 'Option' })
   else
      vim.opt_local.number = nu.number
      vim.opt_local.relativenumber = nu.relativenumber
      Util.info('Enabled line numbers', { title = 'Option' })
   end
end, { desc = 'Toggle line number visibility' })

-- Toggle Word Wrap
vim.keymap.set('n', '<leader>ow', function()
   vim.wo.wrap = not vim.wo.wrap
   local status = vim.wo.wrap and 'enabled' or 'disabled'
   Util.info('Word wrap ' .. status, { title = 'Option' })
end, { desc = 'Toggle Word Wrap' })

-- Biscuits Toggle
vim.keymap.set('n', '<leader>ob', "<cmd>lua require('nvim-biscuits').toggle_biscuits()<CR>", { desc = 'Toggle Biscuits' })

-- highlights under cursor
vim.keymap.set('n', '<leader>ui', vim.show_pos, { desc = 'Inspect Pos' })

-- Add undo break-points
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')
vim.keymap.set('i', ';', ';<c-g>u')

-- Clear search with <esc>
-- TODO: should this actually clear on inert mode? (case: searching and editing multiple instances. WOuld probably not need the escape command at the end if changed)
vim.keymap.set({ 'i', 'n' }, '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and clear hlsearch' })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
vim.keymap.set('n', '<leader>ur', '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>', { desc = 'Redraw / clear hlsearch / diff update' })

--keywordprg
vim.keymap.set('n', '<leader>sK', '<cmd>norm! K<cr>', { desc = 'Keywordprg' })

-- Flash
-- NOTE: below mapped in plugins/editor/flash.lua
-- keys = { "f", "F", "t", "T", [";"] = "<C-n>", [","] = "<C-p>" },
-- keys = {
--    { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
--    { "S",     mode = { "n", "o", "x" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
--    { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
--    { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
--    { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
-- },

-- NeoTree
-- NOTE: below mapped in core/neo-tree.lua
-- { "<leader>ue", function()
--       require("neo-tree.command").execute({
--       toggle = true, dir = vim.loop.cwd()})
--    end, desc = "Explorer NeoTree (cwd)",
-- },
-- { "<leader>e", "<leader>ue", desc = "Explorer NeoTree (cwd)", remap = true },
-- { "<leader>uE", function()
--       require("neo-tree.command").execute({
--       toggle = true, dir = Util.root() })
--    end, desc = "Explorer NeoTree (root dir)",
-- },
-- { "<leader>ge", function()
--       require("neo-tree.command").execute({
--       source = "git_status", toggle = true })
--    end, desc = "Git explorer",
-- },
-- { "<leader>be", function()
--       require("neo-tree.command").execute({
--       source = "buffers", toggle = true })
--    end, desc = "Buffer explorer",
-- },

-- Markdown Preview
-- NOTE: below mapped in plugins/editor/markdown-preview.lua
-- { "<leader>um", ft = "markdown", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview", },

-- Terminal Mappings
vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'Enter Normal Mode' })
vim.keymap.set('t', '<C-h>', '<cmd>wincmd h<cr>', { desc = 'Go to left window' })
vim.keymap.set('t', '<C-j>', '<cmd>wincmd j<cr>', { desc = 'Go to lower window' })
vim.keymap.set('t', '<C-k>', '<cmd>wincmd k<cr>', { desc = 'Go to upper window' })
vim.keymap.set('t', '<C-l>', '<cmd>wincmd l<cr>', { desc = 'Go to right window' })
vim.keymap.set('t', '<C-/>', '<cmd>close<cr>', { desc = 'Hide terminal' })
vim.keymap.set('t', '<c-_>', '<cmd>close<cr>', { desc = 'which_key_ignore' })

-- floating terminal
-- TODO: fix this Util call
-- local lazyterm = function()
-- 	Util.terminal(nil, { cwd = Util.root() })
-- end

-- TODO: fix these Util calls
-- -- vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<CR>", { desc = "Terminal" })
-- -- vim.keymap.set("n", "<c-/>", "<cmd>ToggleTerm<CR>", { desc = "Terminal (root dir)" })
-- -- vim.keymap.set("n", "<c-_>", "<cmd>ToggleTerm<CR>", { desc = "which_key_ignore" })
-- vim.keymap.set("n", "<leader>t", function()
-- 	Util.terminal()
-- end, { desc = "Terminal (cwd)" })
-- vim.keymap.set("n", "<leader>ut", function()
-- 	Util.terminal()
-- end, { desc = "Terminal (cwd)" })
-- vim.keymap.set("n", "<leader>uT", lazyterm, { desc = "Terminal (root dir)" })
-- vim.keymap.set("n", "<c-/>", lazyterm, { desc = "Terminal (root dir)" })
-- vim.keymap.set("n", "<c-_>", lazyterm, { desc = "which_key_ignore" })

-- Added keys to config file
-- -- Markdown Preview
-- vim.keymap.set("n", "<leader>um", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
-- Second Monitor Settings Toggle
vim.keymap.set('n', '<leader>u2', function()
   vim.opt.wrap = true
   vim.opt.linebreak = true
   vim.opt.scrolloff = 999
   vim.opt.signcolumn = 'no'
   vim.opt.relativenumber = false
   vim.opt.number = false
end, { desc = 'Second Monitor Setting' })

-- Treesitter
-- NOTE: below mapped in plugins/utilities/treesitter.lua
-- { "<c-space>", desc = "Increment selection" },
-- { "<bs>",      desc = "Decrement selection", mode = "x" },
-- keymaps = {
--    init_selection = "<C-space>",
--    node_incremental = "<C-space>",
--    node_decremental = "<bs>",
-- },
-- move = {
--    goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
--    goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
--    goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
--    goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
-- },

--###################
--####  Harpoon  ####
--###################

-- -- Add to List
-- NOTE: below mapped in plugins/editor/harpoon.lua
-- vim.keymap.set("n", "<leader>ha", function()
--    harpoon:list():append()
-- end, { desc = "Append to List" })

-- -- Show Quick Menu
-- NOTE: below mapped in plugins/editor/harpoon.lua
-- vim.keymap.set("n", "<leader>hh", function()
--    harpoon.ui:toggle_quick_menu(harpoon:list())
-- end, { desc = "Show Menu" })
--
-- -- Open Harpoon in Telescope
-- NOTE: below mapped in plugins/editor/harpoon.lua
-- vim.keymap.set("n", "<leader>fh", function()
--    toggle_telescope(harpoon:list())
-- end, { desc = "Find Harpoon" })
-- vim.keymap.set("n", "<leader>hf", function()
--    toggle_telescope(harpoon:list())
-- end, { desc = "Find Harpoon" })
--
-- -- Next/Prev Harpoons
-- NOTE: below mapped in plugins/editor/harpoon.lua
-- vim.keymap.set("n", "<leader>h'", function()
--    harpoon:list():next()
-- end, { desc = "Next Harpoon" })
-- vim.keymap.set("n", "<leader>h;", function()
--    harpoon:list():prev()
-- end, { desc = "Prev Harpoon" })
--
-- -- Select Harpoons
-- NOTE: below mapped in plugins/editor/harpoon.lua
-- vim.keymap.set("n", "<leader>h1", function()
--    harpoon:list():select(1)
-- end, { desc = "Select Harpoon 1" })
-- vim.keymap.set("n", "<leader>h2", function()
--    harpoon:list():select(2)
-- end, { desc = "Select Harpoon 2" })
-- vim.keymap.set("n", "<leader>h3", function()
--    harpoon:list():select(3)
-- end, { desc = "Select Harpoon 3" })
-- vim.keymap.set("n", "<leader>h4", function()
--    harpoon:list():select(4)
-- end, { desc = "Select Harpoon 4" })
-- vim.keymap.set("n", "<leader>h5", function()
--    harpoon:list():select(5)
-- end, { desc = "Select Harpoon 5" })
-- vim.keymap.set("n", "<leader>h6", function()
--    harpoon:list():select(6)
-- end, { desc = "Select Harpoon 6" })
-- vim.keymap.set("n", "<leader>h7", function()
--    harpoon:list():select(7)
-- end, { desc = "Select Harpoon 7" })
-- vim.keymap.set("n", "<leader>h8", function()
--    harpoon:list():select(8)
-- end, { desc = "Select Harpoon 8" })
-- vim.keymap.set("n", "<leader>h9", function()
--    harpoon:list():select(9)
-- end, { desc = "Select Harpoon 9" })

--###############
--####  DAP  ####
--###############

-- DAP
-- NOTE: below mapped in plugins/dap/dap.lua
-- { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
-- { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },

-- DAP UI
-- NOTE: below mapped in plugins/dap/dap.lua
-- { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
-- { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
-- { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
-- { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
-- { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
-- { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
-- { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
-- { "<leader>dj", function() require("dap").down() end, desc = "Down" },
-- { "<leader>dk", function() require("dap").up() end, desc = "Up" },
-- { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
-- { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
-- { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
-- { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
-- { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
-- { "<leader>ds", function() require("dap").session() end, desc = "Session" },
-- { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
-- { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },

--###################
--####  Fun Maps ####
--###################

-- Cellular Automaton
-- vim.keymap.set("n", "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>", { desc = "Life" })

-- Duck
-- NOTE: below mapped in plugins/fun/duck.lua
-- ("n", "<leader>udh", function() require("duck").hatch() end, { desc = "Hatch duck" })
-- ("n", "<leader>udc", function() require("duck").cook() end, { desc = "Cook duck" })

--##################
--####  Plugins ####
--##################

-- Lazy
vim.keymap.set('n', '<leader>pl', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- Mason
-- NOTE: below mapped in plugins/lsp/mason.lua
-- { "<leader>pm", "<cmd>Mason<cr>", desc = "Mason" }

--####################
--####  Utilities ####
--####################

-- Persistence
-- NOTE: below mapped in plugins/utilities/persistence.lua
-- { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
-- { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
-- { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },

-- Toggle Treesitter Conext
-- NOTE: below mapped in plugins/utilities/treesitter-context.lua
-- { "<leader>Et", desc = "Toggle Treesitter Context", },

--#################
--####  Hacks  ####
--#################

-- Disable accidental middle click pasting (for laptop trackpad in Linux)
-- will paste on 4 consecutive middle clicks
vim.keymap.set('n', '<MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('i', '<MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('v', '<MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('c', '<MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('n', '<2-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('i', '<2-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('v', '<2-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('c', '<2-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('n', '<3-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('i', '<3-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('v', '<3-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })
vim.keymap.set('c', '<3-MiddleMouse>', '<Nop>', { desc = 'Disable Middle Click Paste' })

--#####################
--####  Test Maps  ####
--#####################a

-- Insert TODO comment
-- vim.keymap.set("n", "<leader>T", "xx<right>a<space>TODO:<space>", { desc = "Insert TODO comment" })
