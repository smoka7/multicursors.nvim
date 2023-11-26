---@class Utils
local utils = require 'multicursors.utils'
local selections = require 'multicursors.selections'

local api = vim.api

---@class InsertMode
---@field private _au_group number
---@field private _inserted_text string
---@field private _user_update_time integer
---@field private _insert_and_clear function
---@field private _on_cursor_hold function
---@field private _on_insert_char_pre function
---@field private _on_insert_enter function
---@field private _on_insert_leave function
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
            M.insert_text(M._inserted_text)
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
            M.insert_text(M._inserted_text)
            M._inserted_text = ''
        end,
    })
end

---@param config Config
local function set_insert_autocommands(config)
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
    M.insert_text(M._inserted_text)
    M._inserted_text = ''
end
---
---@param text string
M.insert_text = function(text)
    local marks = utils.get_all_selections()
    local ns_id = api.nvim_create_namespace 'multicursors'
    for _, mark in pairs(marks) do
        local selection = api.nvim_buf_get_extmark_by_id(
            0,
            ns_id,
            mark.id,
            { details = true }
        )
        local col = selection[3].end_col
        local row = selection[3].end_row
        api.nvim_buf_set_text(0, row, col, row, col, { text })
    end
    selections._move_forward(vim.fn.strcharlen(text))
end

local delete_char = function()
    utils.call_on_selections(function(selection)
        local col = selection.end_col - 1
        if col < 0 then
            return
        end

        api.nvim_win_set_cursor(0, { selection.end_row + 1, col })
        vim.cmd 'normal! x'
    end)

    selections.reduce_to_char(utils.position.before)
end

M.BS_method = function()
    if M._inserted_text == '' then
        delete_char()
    else
        --delete the text under the cursor cause we can't modify buffer content with expr mappings
        vim.cmd 'normal! X'
        M._inserted_text = M._inserted_text:sub(0, #M._inserted_text - 1)
    end
end

M.Left_method = function()
    M._insert_and_clear()
    selections.move_char_horizontal 'before'
end

M.Right_method = function()
    M._insert_and_clear()
    selections.move_char_horizontal 'after'
end

M.UP_method = function()
    M._insert_and_clear()
    selections.move_by_motion 'k'
end

M.Down_method = function()
    M._insert_and_clear()
    selections.move_by_motion 'j'
end

--- Inserts a new line at selections
M.CR_method = function()
    M._insert_and_clear()

    local CR = api.nvim_replace_termcodes('<cr>', true, false, true)

    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark.row + 1, mark.col + 1 })
        vim.cmd('normal! R' .. CR)
    end)

    selections.move_by_motion 'j^'
end

--- Deletes the word backward
M.C_w_method = function()
    M._insert_and_clear()

    local c_w = api.nvim_replace_termcodes('<C-w>', true, false, true)

    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark.row + 1, mark.end_col })
        vim.cmd('normal! i' .. c_w)
    end)

    -- this does not change extmark position but when
    -- we delete a text extmark start and end col will overlap and
    -- user can't see the extmark when moving so we reduces to a char
    -- to get visible
    selections.reduce_to_char(utils.position.before)
end

--- Deletes the char under selection
M.Del_method = function()
    M._insert_and_clear()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark.row + 1, mark.col + 1 })
        vim.cmd 'normal! x'
    end)

    selections.reduce_to_char(utils.position.before)
end

--- Moves the selections to start of their lines
M.Home_method = function()
    M._insert_and_clear()

    selections.move_by_motion '^'
end

--- Moves the selections to end of their lines
M.End_method = function()
    M._insert_and_clear()

    --HACK we can't go to the last char???
    selections.move_by_motion '$'
    selections.move_char_horizontal 'after'
end

M.C_Right = function()
    selections.move_by_motion 'W'
end

M.C_Left = function()
    selections.move_by_motion 'B'
end

--- Deletes selections til start of line
M.C_u_method = function()
    M._insert_and_clear()

    local c_u = api.nvim_replace_termcodes('<C-u>', true, false, true)
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark.row + 1, mark.end_col })
        vim.cmd('normal! i' .. c_u)
    end)

    selections.reduce_to_char(utils.position.before)
end

--- Listens for every char press and inserts the text before leaving insert mode
---@param config Config
M.insert = function(config)
    set_insert_autocommands(config)
    selections.reduce_to_char(utils.position.before)
end

---@param config Config
M.append = function(config)
    set_insert_autocommands(config)
    selections.reduce_to_char(utils.position.on)
end

M.exit = function()
    api.nvim_clear_autocmds { group = M._au_group }
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
        'n',
        true
    )
    vim.b.MultiCursorSubLayer = nil
end

return M
