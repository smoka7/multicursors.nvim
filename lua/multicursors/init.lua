---@type Highlight
local highlight = require 'multicursors.highlight'

---@type Config
local default_config = require 'multicursors.config'

---@type Utils
local utils = require 'multicursors.utils'

---@type Search
local search = require 'multicursors.search'

---@type Layers
local layers = require 'multicursors.layers'

local M = {}

local function create_commands()
    vim.api.nvim_create_user_command('MCstart', function()
        M.start()
    end, {})

    vim.api.nvim_create_user_command('MCvisual', function()
        M.search_visual()
    end, { range = 0 })

    vim.api.nvim_create_user_command('MCunderCursor', function()
        M.new_under_cursor()
    end, {})

    vim.api.nvim_create_user_command('MCclear', function()
        M.exit()
    end, {})

    vim.api.nvim_create_user_command('MCpattern', function()
        M.new_pattern()
    end, {})

    vim.api.nvim_create_user_command('MCvisualPattern', function()
        M.new_pattern_visual()
    end, { range = 0 })
end

--- Returns true when we are in visual mode
---@return boolean
local function is_visual_mode()
    local mode = vim.fn.mode()
    return mode == 'v' or mode == 'V' or mode == '<C-v>'
end

M.start = function()
    local found
    if is_visual_mode() then
        found = search.find_selected()
    else
        found = search.find_cursor_word()
    end

    if found then
        layers.normal_hydra:activate()
    end
end

M.new_under_cursor = function()
    search.new_under_cursor()
    layers.normal_hydra:activate()
end

M.search_visual = function()
    if search.find_selected() then
        layers.normal_hydra:activate()
    end
end

M.new_pattern = function()
    if search.find_pattern(true) then
        layers.normal_hydra:activate()
    end
end

M.new_pattern_visual = function()
    if search.find_pattern(false) then
        layers.normal_hydra:activate()
    end
end

M.exit = function()
    utils.exit()
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
        create_commands()
    end

    layers.create_normal_hydra(config)
end

return M
