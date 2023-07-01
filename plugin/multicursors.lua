local utils = require 'multicursors.utils'
local normal_mode = require 'multicursors.normal_mode'

vim.api.nvim_create_user_command('MCstart', function()
    normal_mode.start()
end, {})

vim.api.nvim_create_user_command('MCclear', function()
    utils.exit()
end, {})
