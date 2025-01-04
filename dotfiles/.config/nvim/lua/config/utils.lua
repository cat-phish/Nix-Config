-- lua/config/utils.lua
-- TODO: implement this in place of vim.notify calls

-- call all of these by doing
-- local Util = require('config.utils')

local M = {}

-- Util.warn('Explanation text here', { title = 'Title goes here' })
function M.warn(message, opts)
   vim.notify(message, vim.log.levels.WARN, opts)
end

-- Util.info('Explanation text here', { title = 'Title goes here' })
function M.info(message, opts)
   vim.notify(message, vim.log.levels.INFO, opts)
end

return M
