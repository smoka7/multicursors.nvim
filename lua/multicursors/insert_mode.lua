---@class Utils
local utils = require 'multicursors.utils'
local api = vim.api

---@class InsertMode
---@field _au_group number
---@field _inserted_text string
local M = {}

M._inserted_text = ''

M._au_group = api.nvim_create_augroup('multicursors', { clear = true })

M._user_update_time = 4000

---
---@param config Config
M._on_insert_enter = function(config)
    api.nvim_create_autocmd({ 'InsertEnter' }, {
        group = M._au_group,
        callback = function()
            M._user_update_time = vim.opt.updatetime
            vim.opt.updatetime = config.updatetime
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
            if M._inserted_text == '' then
                return
            end
            utils.insert_text(M._inserted_text)
            M._inserted_text = ''
        end,
    })
end

---@param config Config
local function set_insert_autocommands(config)
    vim.b.MultiCursorInsert = true
    M._on_insert_enter(config)
    M._on_cursor_hold()
    M._on_insert_char_pre()
    M._on_insert_leave()
    vim.cmd.startinsert()
end

M._insert_and_clear = function()
    if M._inserted_text == '' then
        return
    end
    utils.insert_text(M._inserted_text)
    M._inserted_text = ''
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

--- listens for every char press and inserts the text before leaving insert mode
--TODO esc go to multicursor normal
---@param config Config
M.insert = function(config)
    set_insert_autocommands(config)
    utils.update_selections(utils.position.before)
end

---@param config Config
M.append = function(config)
    set_insert_autocommands(config)
    utils.update_selections(utils.position.after)
end

M.exit = function()
    api.nvim_clear_autocmds { group = M._au_group }
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
        'n',
        true
    )
    vim.b.MultiCursorInsert = nil
    vim.cmd [[redraw!]]
end

return M
