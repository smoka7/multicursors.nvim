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

--- Inserts a new line at selections
M.CR_method = function()
    M._insert_and_clear()

    local CR = api.nvim_replace_termcodes('<cr>', true, false, true)

    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] + 1 })
        vim.cmd('normal! R' .. CR)
    end, true, true)

    utils.move_selections_vertical(1)
    --HACK selections should start at line start
    -- but move_selections_vertical doesn't changes col values
    utils.move_selections_horizontal(-vim.v.maxcol)
end

--- Deletes the word backward
M.C_w_method = function()
    M._insert_and_clear()

    local c_w = api.nvim_replace_termcodes('<C-w>', true, false, true)

    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] + 1 })
        vim.cmd('normal! i' .. c_w)
    end, true, true)

    -- this does not change extmark position but when
    -- we delete a text extmark start and end col will overlap and
    -- user can't see the extmark when moving we increment end col so selection gets visible
    utils.move_selections_horizontal(0)
end

--- Deletes the char under selection
M.Del_method = function()
    M._insert_and_clear()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] + 1 })
        vim.cmd 'normal! x'
    end, true, true)

    utils.move_selections_horizontal(0)
end

--- Moves the selections to start of their lines
M.Home_method = function()
    M._insert_and_clear()

    utils.move_selections_horizontal(-vim.v.maxcol)
end

--- Moves the selections to end of their lines
M.End_method = function()
    M._insert_and_clear()

    utils.move_selections_horizontal(vim.v.maxcol)
end

--- Deletes selections til start of line
M.C_u_method = function()
    M._insert_and_clear()

    local c_u = api.nvim_replace_termcodes('<C-u>', true, false, true)
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] + 1 })
        vim.cmd('normal! i' .. c_u)
    end, true, true)

    utils.move_selections_horizontal(0)
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
    vim.b.MultiCursorSubLayer = nil
end

return M
