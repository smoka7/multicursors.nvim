---@class Utils
local utils = require 'multicursors.utils'
local api = vim.api

---@class InsertMode
---@field _au_group number
---@field _inserted_text string
---@field _user_mappings any[]?
local M = {}

M._inserted_text = ''

M._au_group = api.nvim_create_augroup('multicursors', { clear = true })

M._user_mappings = nil
M._user_update_time = 4000

---
---@param config Config
M._on_insert_enter = function(config)
    api.nvim_create_autocmd({ 'InsertEnter' }, {
        group = M._au_group,
        callback = function()
            M._user_update_time = vim.opt.updatetime
            vim.opt.updatetime = config.updatetime
            M._save_user_mappings()
            M._register_mappings()
        end,
    })
end

M._on_insert_char_pre = function()
    api.nvim_create_autocmd({ 'InsertCharPre' }, {
        group = M._au_group,
        callback = function()
            M._inserted_text = M._inserted_text .. vim.v.char
        end,
    })
end

M._on_cursor_hold = function()
    api.nvim_create_autocmd({ 'CursorHoldI' }, {
        group = M._au_group,
        callback = function()
            if M._inserted_text == '' then
                return
            end
            utils.insert_text(M._inserted_text)
            M._inserted_text = ''
        end,
    })
end

M._on_insert_leave = function()
    api.nvim_create_autocmd({ 'InsertLeave' }, {
        group = M._au_group,
        callback = function()
            vim.opt.updatetime = M._user_update_time
            M._restore_user_mappings()
            if M._inserted_text == '' then
                M.exit()
                return
            end
            utils.insert_text(M._inserted_text)
            M._inserted_text = ''
            M.exit()
        end,
    })
end

---@param config Config
local function set_insert_autocommands(config)
    M._on_insert_enter(config)
    M._on_cursor_hold()
    M._on_insert_char_pre()
    M._on_insert_leave()
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
            { expr = false, buffer = true, noremap = true }
        )
    end
end

M._insert_and_clear = function()
    if M._inserted_text == '' then
        return
    end
    utils.insert_text(M._inserted_text)
    M._inserted_text = ''
end

--- returns true if we have a mapping for lhs in insert mode
---@param lhs string
---@return boolean
local mapped = function(lhs)
    for _, map in ipairs(M._user_mappings) do
        if lhs == map.lhs then
            vim.keymap.set('i', map.lhs, map.rhs or map.callback)
            return true
        end
    end
    return false
end

M._restore_user_mappings = function()
    for _, map in ipairs(M._insert_mode_mappings) do
        if not mapped(map.lhs) then
            vim.keymap.del('i', map.lhs, { buffer = 0 })
        end
    end
    M._user_mappings = nil
end

M.BS_method = function()
    if M._inserted_text == '' then
        utils.delete_char()
    else
        --delete the text under the cursor cause we can't modify buffer content with expr mappings
        vim.cmd 'normal X'
        M._inserted_text = M._inserted_text:sub(0, #M._inserted_text - 1)
    end
end

M.Left_method = function()
    M._insert_and_clear()
    utils.move_selections_horizontal(-1)
end

M.Right_method = function()
    M._insert_and_clear()
    utils.move_selections_horizontal(1)
end

M.UP_method = function()
    M._insert_and_clear()
    utils.move_selections_vertical(-1)
end

M.Down_method = function()
    M._insert_and_clear()
    utils.move_selections_vertical(1)
end

---@type Mapping[]
M._insert_mode_mappings = {
    { lhs = '<BS>', rhs = M.BS_method },
    { lhs = '<Left>', rhs = M.Left_method },
    { lhs = '<Right>', rhs = M.Right_method },
    { lhs = '<Up>', rhs = M.UP_method },
    { lhs = '<Down>', rhs = M.Down_method },
}

--- listens for every char press and inserts the text before leaving insert mode
--TODO esc go to multicursor normal
---@param config Config
M.start = function(config)
    utils.update_selections(utils.position.before)
    set_insert_autocommands(config)
end

---@param config Config
M.append = function(config)
    utils.update_selections(utils.position.after)
    set_insert_autocommands(config)
end

M.exit = function()
    api.nvim_clear_autocmds { group = M._au_group }
    utils.exit()
    vim.cmd [[redraw!]]
end

return M
