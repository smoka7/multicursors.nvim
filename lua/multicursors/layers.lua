local Hydra = require 'hydra'

---@type InsertMode
local insert_mode = require 'multicursors.insert_mode'

---@type NormalMode
local normal_mode = require 'multicursors.normal_mode'

---@type Utils
local utils = require 'multicursors.utils'

---@class Layers
local L = {}

L.normal_hydra = nil

L.insert_hydra = nil

---
---@param config Config
---@return table
L.generate_normal_heads = function(config)
    local heads = {}
    for i, value in pairs(config.normal_keys) do
        if value.method then
            heads[#heads + 1] = {
                i,
                value.method,
                {
                    -- nowait = true ,
                    desc = value.desc,
                },
            }
        end
    end
    local enter_insert = function(callback)
        -- tell hydra that we're going to insert mode so it doesn't clear the selection
        vim.b.MultiCursorSubLayer = true

        callback()
        L.create_insert_hydra(config)
        L.insert_hydra:activate()
    end
    heads[#heads + 1] = {
        '<esc>',
        nil,
        { desc = 'exit multi cursor mode', exit = true },
    }

    heads[#heads + 1] = {
        'i',
        function()
            enter_insert(function()
                insert_mode.insert(config)
            end)
        end,
        { desc = 'insert mode', exit = true },
    }

    heads[#heads + 1] = {
        'c',
        function()
            enter_insert(function()
                normal_mode.change(config)
            end)
        end,
        { desc = 'change mode', exit = true },
    }

    heads[#heads + 1] = {
        'a',
        function()
            enter_insert(function()
                insert_mode.append(config)
            end)
        end,
        { desc = 'append mode', exit = true },
    }

    heads[#heads + 1] = {
        'e',
        function()
            vim.b.MultiCursorSubLayer = true
            L.create_extend_hydra(config)
            L.extend_hydra:activate()
        end,
        { desc = 'extend mode', exit = true },
    }
    return heads
end

---
---@param config Config
L.create_normal_hydra = function(config)
    L.normal_hydra = Hydra {
        name = 'Multi Cursor',
        hint = [[Multi Cursor]],
        config = {
            buffer = 0,
            on_enter = function()
                vim.b.MultiCursorAnchorStart = true
            end,
            on_exit = function()
                if not vim.b.MultiCursorSubLayer then
                    utils.exit()
                end
            end,
            color = 'pink',
        },
        mode = 'n',
        heads = L.generate_normal_heads(config),
    }
end

---@param config Config
---@return table
L.generate_insert_heads = function(config)
    local heads = {}
    for i, value in pairs(config.insert_keys) do
        if value.method then
            heads[#heads + 1] = {
                i,
                value.method,
                {
                    desc = value.desc,
                },
            }
        end
    end
    return heads
end

---@param config Config
L.create_insert_hydra = function(config)
    L.insert_hydra = Hydra {
        name = 'Multi Cursor insert',
        hint = [[Multi Cursor Insert]],
        mode = 'i',
        config = {
            buffer = 0,
            on_enter = function() end,
            on_exit = function()
                insert_mode.exit()
                vim.defer_fn(function()
                    L.normal_hydra:activate()
                end, 20)
            end,
            color = 'pink',
        },
        heads = L.generate_insert_heads(config),
    }
end

---@param config Config
---@return table
L.generate_extend_head = function(config)
    local heads = {}
    for i, value in pairs(config.extend_keys) do
        if value.method then
            heads[#heads + 1] = {
                i,
                value.method,
                {
                    desc = value.desc,
                },
            }
        end
    end
    return heads
end

---@param config Config
L.create_extend_hydra = function(config)
    L.extend_hydra = Hydra {
        name = 'Multi Cursor Extend',
        hint = [[Multi Cursor Extend]],
        mode = 'n',
        config = {
            buffer = 0,
            on_enter = function()
                vim.cmd.redraw()
            end,
            on_exit = function()
                vim.b.MultiCursorSubLayer = nil
                vim.defer_fn(function()
                    L.normal_hydra:activate()
                end, 20)
            end,
            color = 'pink',
        },
        heads = L.generate_extend_head(config),
    }
end
return L
