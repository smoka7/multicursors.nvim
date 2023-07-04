local libmodal = require 'libmodal'

---@type Highlight
local highlight = require 'multicursors.highlight'

---@type Config
local default_config = require 'multicursors.config'

---@type NormalMode
local normal_mode = require 'multicursors.normal_mode'

---@type Utils
local utils = require 'multicursors.utils'

local M = {}

local function create_commands()
    vim.api.nvim_create_user_command('MCstart', function()
        M.cursor_word()
    end, {})

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

M.layer = {}

---@param config Config
M.create_normal_mappings = function(config)
    if not config.keys then
        return
    end
    M.layer = libmodal.layer.new {

        n = {
            [config.keys.align_selections_before] = {
                rhs = normal_mode.align_selections_before,
            },
            [config.keys.align_selections_start] = {
                rhs = normal_mode.align_selections_start,
            },
            -- --TODO
            -- [config.keys.insert_mode] = {
            --     rhs = insert_mode.insert,
            -- },
            -- [config.keys.append_mode] = {
            --     rhs = insert_mode.append,
            -- },
            -- --TODO
            -- [config.keys.change_mode] = {
            --     rhs = normal_mode.change,
            -- },

            [config.keys.create_up] = {
                rhs = normal_mode.create_up,
            },
            [config.keys.create_down] = {
                rhs = normal_mode.create_down,
            },
            [config.keys.skip_create_up] = {
                rhs = normal_mode.skip_create_up,
            },
            [config.keys.skip_create_down] = {
                rhs = normal_mode.skip_create_down,
            },

            [config.keys.clear_others] = {
                rhs = normal_mode.clear_others,
            },
            [config.keys.goto_next] = {
                rhs = normal_mode.goto_next,
            },
            [config.keys.goto_prev] = {
                rhs = normal_mode.goto_prev,
            },
            [config.keys.find_next] = {
                rhs = normal_mode.find_next,
            },
            [config.keys.find_prev] = {
                rhs = normal_mode.find_prev,
            },
            [config.keys.skip_find_next] = {
                rhs = normal_mode.skip_find_next,
            },

            [config.keys.skip_find_prev] = {
                rhs = normal_mode.skip_find_prev,
            },

            [config.keys.delete] = {
                rhs = normal_mode.delete,
            },
            [config.keys.paste_after] = {
                rhs = normal_mode.paste_after,
            },
            [config.keys.paste_before] = {
                rhs = normal_mode.paste_before,
            },
            [config.keys.yank] = {
                rhs = normal_mode.yank,
            },

            [config.keys.dot_repeat] = {
                rhs = normal_mode.dot_repeat,
            },
            --[config.keys.run_macro] = {
            --    rhs = normal_mode.run_macro,
            --    { expr = false },
            --},
            [config.keys.run_normal_command] = {
                rhs = normal_mode.normal_command,
            },
        },
    }

    M.layer:map('n', config.keys.run_macro, function()
        normal_mode.run_macro()
    end, { expr = false })

    M.layer:map('n', '<Esc>', function()
        M.layer:exit()
        utils.exit()
    end, {})

    M.layer:map('n', '<C-c>', function()
        utils.exit()
        M.layer:exit()
    end, {})
end

---
---@param config Config
M.set_layer = function(config)
    M.create_normal_mappings(config)
end

M.cursor_word = function()
    normal_mode.find_cursor_word()
    M.layer:enter()
end

M.new_under_cursor = function()
    normal_mode.new_under_cursor()
    M.layer:enter()
end

M.new_pattern = function()
    normal_mode.pattern(true)
    M.layer:enter()
end

M.new_pattern_visual = function()
    normal_mode.pattern(false)
    M.layer:enter()
end

M.exit = function()
    utils.exit()
    M.layer:exit()
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

    M.set_layer(config)

    if config.create_commands then
        create_commands()
    end
end

return M
