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

L.extend_hydra = nil

---
---@param keys Dictionary: { [string]: Action }
---@param nowait boolean
---@param show_desc boolean
---@return Head[]
local generate_heads = function(keys, nowait, show_desc)
    ---@type Head[]
    local heads = {}
    for i, value in pairs(keys) do
        local description = nil
        if show_desc then
            description = value.desc or value.opts.desc
        end

        if value.method then
            heads[#heads + 1] = {
                i,
                value.method,
                {
                    desc = description,
                    nowait = nowait,
                },
            }
        end
    end

    return heads
end

---
---@param config Config
---@return Head[]
L.generate_normal_heads = function(config)
    local heads = generate_heads(
        config.normal_keys,
        config.nowait,
        config.generate_hints.normal
    )
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
    local heads = L.generate_normal_heads(config)

    L.normal_hydra = Hydra {
        name = 'Multi Cursor',
        hint = utils.generate_hints(config, heads, 'normal'),
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
            hint = config.hint_config,
        },
        mode = 'n',
        heads = heads,
    }
end

---@param config Config
---@return Head[]
L.generate_insert_heads = function(config)
    return generate_heads(
        config.insert_keys,
        config.nowait,
        config.generate_hints.insert
    )
end

---@param config Config
L.create_insert_hydra = function(config)
    local heads = L.generate_insert_heads(config)
    L.insert_hydra = Hydra {
        name = 'Multi Cursor insert',
        hint = utils.generate_hints(config, heads, 'insert'),
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
            hint = config.hint_config,
        },
        heads = heads,
    }
end

---@param config Config
---@return Head[]
L.generate_extend_heads = function(config)
    return generate_heads(
        config.extend_keys,
        config.nowait,
        config.generate_hints.extend
    )
end

---@param config Config
L.create_extend_hydra = function(config)
    local heads = L.generate_extend_heads(config)

    L.extend_hydra = Hydra {
        name = 'Multi Cursor Extend',
        hint = utils.generate_hints(config, heads, 'extend'),
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
            hint = config.hint_config,
        },
        heads = heads,
    }
end

return L
