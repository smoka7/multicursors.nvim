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
---@return Head[]
local set_heads_options = function(keys, nowait)
    ---@type Head[]
    local heads = {}
    for lhs, action in pairs(keys) do
        if action.method ~= false then
            local opts = action.opts or {}

            if action.opts.nowait ~= nil then
                opts.nowait = action.opts.nowait
            else
                opts.nowait = nowait
            end

            heads[#heads + 1] = {
                lhs,
                action.method,
                opts,
            }
        end
    end

    return heads
end

--- Creates a hint for a head
--- when necessary adds padding or cuts the hint for aligning
---@param head Head
---@param max_hint_length integer
---@return string
local function get_hint(head, max_hint_length)
    if not head[3].desc or head[3].desc == '' then
        return ''
    end

    local hint = ' _' .. head[1] .. '_ : ' .. head[3].desc .. '^'
    local length = vim.fn.strdisplaywidth(hint)
    if length < max_hint_length then
        hint = hint .. string.rep(' ', max_hint_length - length)
    elseif length > max_hint_length then
        hint = string.sub(hint, 0, max_hint_length - 5) .. '... '
    end

    return hint
end

-- Generates hints based on the configuration and input parameters.
---@param config Config configuration.
---@param heads Head[]
---@param mode string indicating the mode.
---@return string hints as a string.
local generate_hints = function(config, heads, mode)
    if config.generate_hints[mode] == false then
        return 'MultiCursor ' .. mode .. ' mode'
    elseif type(config.generate_hints[mode]) == 'string' then
        return config.generate_hints[mode]
    elseif type(config.generate_hints[mode]) == 'function' then
        return config.generate_hints[mode](heads)
    end

    table.sort(heads, function(a, b)
        -- put the head with empty desc at the end
        if a[3].desc == '' then
            return false
        end

        -- put the special characters at the end
        local is_special_a = not string.match(a[1], '[%a%d]')
        local is_special_b = not string.match(b[1], '[%a%d]')
        if is_special_a and not is_special_b then
            return false
        elseif not is_special_a and is_special_b then
            return true
        else
            return a[1] < b[1]
        end
    end)

    local str = ' MultiCursor: ' .. mode .. ' mode'

    local max_hint_length = config.generate_hints.config.max_hint_length
    local columns = config.generate_hints.config.column_count
        or math.floor(
            vim.api.nvim_get_option_value('columns', {}) / max_hint_length
        )

    local line
    for i = 0, math.floor(#heads / columns) do
        line = ''
        for j = 1, columns, 1 do
            if heads[(i * columns) + j] then
                line = line
                    .. get_hint(heads[(i * columns) + j], max_hint_length)
            end
        end

        if line ~= '' then
            str = str .. '\n' .. line
        end
    end

    return str
end

---
---@param config Config
---@return Head[]
L.generate_normal_heads = function(config)
    local heads = set_heads_options(config.normal_keys, config.nowait)
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
        { desc = 'exit', exit = true, nowait = config.nowait },
    }

    heads[#heads + 1] = {
        config.mode_keys.insert,
        function()
            enter_insert(function()
                insert_mode.insert(config)
            end)
        end,
        { desc = 'insert mode', exit = true, nowait = config.nowait },
    }

    heads[#heads + 1] = {
        config.mode_keys.change,
        function()
            enter_insert(function()
                normal_mode.change(config)
            end)
        end,
        { desc = 'change mode', exit = true, nowait = config.nowait },
    }

    heads[#heads + 1] = {
        config.mode_keys.append,
        function()
            enter_insert(function()
                insert_mode.append(config)
            end)
        end,
        { desc = 'append mode', exit = true, nowait = config.nowait },
    }

    heads[#heads + 1] = {
        config.mode_keys.extend,
        function()
            vim.b.MultiCursorSubLayer = true
            L.create_extend_hydra(config)
            L.extend_hydra:activate()
        end,
        { desc = 'extend mode', exit = true, nowait = config.nowait },
    }

    return heads
end

---
---@param config Config
L.create_normal_hydra = function(config)
    local heads = L.generate_normal_heads(config)

    L.normal_hydra = Hydra {
        name = 'MC Normal',
        hint = generate_hints(config, heads, 'normal'),
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
    return set_heads_options(config.insert_keys, config.nowait)
end

---@param config Config
L.create_insert_hydra = function(config)
    local heads = L.generate_insert_heads(config)
    L.insert_hydra = Hydra {
        name = 'MC Insert',
        hint = generate_hints(config, heads, 'insert'),
        mode = 'i',
        config = {
            buffer = 0,
            on_enter = function() end,
            on_exit = function()
                vim.defer_fn(function()
                    insert_mode.exit()
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
    return set_heads_options(config.extend_keys, config.nowait)
end

---@param config Config
L.create_extend_hydra = function(config)
    local heads = L.generate_extend_heads(config)

    L.extend_hydra = Hydra {
        name = 'MC Extend',
        hint = generate_hints(config, heads, 'extend'),
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
