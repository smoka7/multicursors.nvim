local utils = require 'multicursors.utils'
local api = vim.api

---@class InsertMode
local M = {}

M._inserted_text = ''

--- @type number
M._au_group = api.nvim_create_augroup('multicursors', { clear = true })

---@type any[]?
M._user_mappings = nil

--- listens for every char press and inserts the text before leaving insert mode
--TODO create a timer and update the cursors for better ux
--TODO sholud remap all cursor movements
--TODO esc go to multicursor normal
M.start = function()
    api.nvim_create_autocmd({ 'InsertEnter' }, {
        group = M._au_group,
        callback = function()
            M._save_user_mappings()
            M._register_mappings()
        end,
    })

    api.nvim_create_autocmd({ 'InsertLeave' }, {
        group = M._au_group,
        callback = function()
            M._restore_user_mappings()
            if M._inserted_text == '' then
                return
            end
            utils.insert_text(M._inserted_text, true)
            M._inserted_text = ''
            M.exit()
        end,
    })

    api.nvim_create_autocmd({ 'InsertCharPre' }, {
        group = M._au_group,
        callback = function()
            M._inserted_text = M._inserted_text .. vim.v.char
        end,
    })
end

M._save_user_mappings = function()
    M._user_mappings = api.nvim_get_keymap 'i'
end

M._register_mappings = function()
    for _, map in ipairs(M._insert_mode_mappings) do
        vim.keymap.set(
            'i',
            map.lhs,
            map.rhs,
            { expr = true, buffer = true, noremap = true }
        )
    end
end

--- returns true if we have a mapping for lhs in insert mode
---@param lhs string
---@return boolean
local mapped = function(lhs)
    for _, value in ipairs(M._insert_mode_mappings) do
        if lhs == value.lhs then
            return true
        end
    end
    return false
end

M._restore_user_mappings = function()
    for _, map in ipairs(M._user_mappings) do
        if map.lhs == '<BS>' then
            if mapped(map.lhs) then
                vim.keymap.set('i', map.lhs, map.rhs or map.callback)
            end
        end
    end
    M._user_mappings = nil
end

M.BS_method = function()
    if M._inserted_text ~= '' then
        M._inserted_text = M._inserted_text:sub(0, #M._inserted_text - 1)
    end

    return '<BS>'
end

---@type Mapping[]
M._insert_mode_mappings = {
    { lhs = '<BS>', rhs = M.BS_method },
}

M.exit = function()
    api.nvim_clear_autocmds { group = M._au_group }
end

return M
