---@type Highlight
local highlight = require 'multicursors.highlight'

---@type Config
local default_config = require 'multicursors.config'

---@type Utils
local utils = require 'multicursors.utils'

---@type NormalMode
local normal_mode = require 'multicursors.normal_mode'

local M = {}

---@param config Config
local function create_commands(config)
    vim.api.nvim_create_user_command('MCstart', function()
        normal_mode.start(config)
    end, {})

    vim.api.nvim_create_user_command('MCvisual', function()
        normal_mode.search_selected(config)
    end, { range = 0 })

    vim.api.nvim_create_user_command('MCunderCursor', function()
        normal_mode.new_selection(config)
    end, {})

    vim.api.nvim_create_user_command('MCclear', function()
        utils.exit()
    end, {})

    vim.api.nvim_create_user_command('MCpattern', function()
        normal_mode.pattern(config, true)
    end, {})

    vim.api.nvim_create_user_command('MCvisualPattern', function()
        normal_mode.pattern(config, false)
    end, { range = 0 })
end

---@param opts Config
M.setup = function(opts)
    local config = vim.tbl_deep_extend('keep', opts, default_config)
    vim.g.MultiCursorDebug = config.DEBUG_MODE

    highlight.set_highlights()

    vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
        callback = function()
            highlight.set_highlights()
        end,
    })

    if config.create_commands then
        create_commands(config)
    end
end

return M
