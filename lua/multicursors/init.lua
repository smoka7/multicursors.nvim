local highlight = require 'multicursors.highlight'
local default_config = require 'multicursors.config'
local utils = require 'multicursors.utils'
local normal_mode = require 'multicursors.normal_mode'

local M = {}

---@param config Config
local function create_commands(config)
    vim.api.nvim_create_user_command('MCstart', function()
        normal_mode.start(config)
    end, {})

    vim.api.nvim_create_user_command('MCclear', function()
        utils.exit()
    end, {})
end

---@param opts Config
M.setup = function(opts)
    local config = vim.tbl_deep_extend('keep', opts, default_config)
    vim.g.MultiCursorDebug = config.DEBUG_MODE

    highlight.set_highlights()

    if config.create_commands then
        create_commands(config)
    end
end

return M
