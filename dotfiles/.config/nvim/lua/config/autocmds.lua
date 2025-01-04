-- TODO: go through whole config and add all autocommands from other files as comments

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
   group = vim.api.nvim_create_augroup('checktime', { clear = true }),
   callback = function()
      if vim.o.buftype ~= 'nofile' then
         vim.cmd 'checktime'
      end
   end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
   group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
   callback = function()
      vim.highlight.on_yank()
   end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ 'VimResized' }, {
   group = vim.api.nvim_create_augroup('resize_splits', { clear = true }),
   callback = function()
      local current_tab = vim.fn.tabpagenr()
      vim.cmd 'tabdo wincmd ='
      vim.cmd('tabnext ' .. current_tab)
   end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd('BufReadPost', {
   group = vim.api.nvim_create_augroup('last_loc', { clear = true }),
   callback = function(event)
      local exclude = { 'gitcommit' }
      local buf = event.buf
      if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
         return
      end
      vim.b[buf].lazyvim_last_loc = true
      local mark = vim.api.nvim_buf_get_mark(buf, '"')
      local lcount = vim.api.nvim_buf_line_count(buf)
      if mark[1] > 0 and mark[1] <= lcount then
         pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
   end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
   group = vim.api.nvim_create_augroup('close_with_q', { clear = true }),
   pattern = {
      'PlenaryTestPopup',
      'help',
      'lspinfo',
      'man',
      'notify',
      'qf',
      'query',
      'spectre_panel',
      'startuptime',
      'tsplayground',
      'neotest-output',
      'checkhealth',
      'neotest-summary',
      'neotest-output-panel',
      'trouble',
      'wtf',
   },
   callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
   end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
   group = vim.api.nvim_create_augroup('wrap_spell', { clear = true }),
   pattern = { 'gitcommit' },
   callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
   end,
})

-- wrap and check for spell in markdown filetypes
vim.api.nvim_create_autocmd('FileType', {
   group = vim.api.nvim_create_augroup('markdown_view', { clear = true }),
   pattern = { 'markdown' },
   callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.textwidth = 80
      vim.opt_local.spell = true
      -- vim.opt_local.linebreak = true
      -- vim.opt_local.cursorcolumn = true
      vim.opt_local.colorcolumn = '80'
   end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ 'FileType' }, {
   group = vim.api.nvim_create_augroup('json_conceal', { clear = true }),
   pattern = { 'json', 'jsonc', 'json5' },
   callback = function()
      vim.opt_local.conceallevel = 0
   end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
   group = vim.api.nvim_create_augroup('auto_create_dir', { clear = true }),
   callback = function(event)
      if event.match:match '^%w%w+://' then
         return
      end
      local file = vim.loop.fs_realpath(event.match) or event.match
      vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
   end,
})

-- NOTE: deprecated in favor of temp/permanent toggling in the keymaps
-- -- Auto switch back to relative line numbers numerous events
-- vim.api.nvim_create_autocmd({ "BufLeave", "InsertEnter", "CmdlineLeave", "WinLeave" }, {
-- 	pattern = "*",
-- 	group = vim.api.nvim_create_augroup("reset_relnum_normal", { clear = true }),
-- 	callback = function()
-- 		if vim.o.nu then
-- 			vim.opt.relativenumber = true
-- 			-- vim.cmd("redraw")
-- 		end
-- 	end,
-- })

-- Open Neo-tree on startup
vim.api.nvim_create_autocmd('VimEnter', {
   callback = function()
      local args = vim.fn.argv()
      if #args == 0 then
         -- Do nothing if no arguments are provided
         return
      elseif vim.fn.isdirectory(args[1]) == 1 then
         -- Open Neo-tree and focus it if the first argument is a directory
         vim.cmd('Neotree show dir=' .. args[1])

         -- Simulate pressing <C-w>h after a short delay to focus the Neo-tree pane
         vim.defer_fn(function()
            -- HACK: Send the literal keypresses <C-w>h because of neotree not showing correct background
            -- color until its manualy switched into when opening with dir argument
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-w>h', true, true, true), 'n', true)
         end, 10)
      else
         -- Open Neo-tree alongside the file (if it's not a directory)
         vim.defer_fn(function()
            vim.cmd 'Neotree show'
            -- Redraw to force UI to refresh
            vim.cmd 'redraw'
         end, 10)
      end
   end,
})

-- Switch to Normal mode when Neo-Tree window is entered
vim.api.nvim_create_autocmd({ 'WinEnter' }, {
   pattern = 'neo-tree*',
   group = vim.api.nvim_create_augroup('neotree_normal_mode', { clear = true }),
   command = 'stopinsert',
})

-- Display time since last nvim config once per 8 hours
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
   pattern = vim.fn.expand '~' .. '/.config/nvim/*',
   group = vim.api.nvim_create_augroup('nvim_config_check', { clear = true }),
   callback = function()
      local function convert_seconds(seconds)
         local units = { 'year', 'day', 'hour', 'minute', 'second' }
         local lengths = { 31536000, 86400, 3600, 60, 1 }
         local result = ''

         for i, unit in ipairs(units) do
            local val = math.floor(seconds / lengths[i])
            if val > 0 then
               result = result .. val .. ' ' .. unit .. (val > 1 and 's' or '') .. ' '
               seconds = seconds % lengths[i]
            end
         end

         return result
      end

      local function run_config_pulse_once_per_day()
         -- TODO: change stdpath to use config or state
         local time_file_path = vim.fn.stdpath 'data' .. '/config_pulse_last_run'
         local longest_stretch_file_path = vim.fn.stdpath 'data' .. '/config_pulse_longest_stretch'
         local last_run_time = ''
         local longest_stretch = ''

         -- Check if the time file exists before trying to read from it
         if vim.loop.fs_stat(time_file_path) then
            local time_file = io.open(time_file_path, 'r')
            if time_file then
               last_run_time = time_file:read '*a'
               time_file:close()
            end
         else
            -- If the time file does not exist, create it and write the current time
            local time_file = io.open(time_file_path, 'w')
            if time_file then
               time_file:write(tostring(os.time()))
               time_file:close()
            end
         end

         -- Check if the longest stretch file exists before trying to read from it
         if vim.loop.fs_stat(longest_stretch_file_path) then
            local longest_stretch_file = io.open(longest_stretch_file_path, 'r')
            if longest_stretch_file then
               longest_stretch = longest_stretch_file:read '*a'
               longest_stretch_file:close()
            end
         else
            -- If the longest stretch file does not exist, create it and write 0
            local longest_stretch_file = io.open(longest_stretch_file_path, 'w')
            if longest_stretch_file then
               longest_stretch_file:write '0'
               longest_stretch_file:close()
            end
         end

         local current_time = os.time()
         local time_since_last_edit = current_time - tonumber(last_run_time)

         -- Update the time file with the current time
         local time_file = io.open(time_file_path, 'w')
         if time_file then
            time_file:write(tostring(current_time))
            time_file:close()
         end

         if time_since_last_edit >= 3600 then
            local time_since_last_edit_str = 'Time since last edit: ' .. convert_seconds(time_since_last_edit)
            local high_score_str = 'High Score: ' .. convert_seconds(tonumber(longest_stretch))

            if time_since_last_edit > tonumber(longest_stretch) then
               local longest_stretch_file = io.open(longest_stretch_file_path, 'w')
               if longest_stretch_file then
                  longest_stretch_file:write(tostring(time_since_last_edit))
                  longest_stretch_file:close()
               end
               vim.notify('New High Score!\n' .. time_since_last_edit_str, vim.log.levels.INFO)
            else
               vim.notify(time_since_last_edit_str .. '\n' .. high_score_str, vim.log.levels.INFO)
            end
         end
      end

      run_config_pulse_once_per_day()
   end,
})
