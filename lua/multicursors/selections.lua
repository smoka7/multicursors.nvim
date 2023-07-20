local utils = require 'multicursors.utils'
local api = vim.api

local S = {}

---
---@param mark Selection
---@param motion string
local get_new_position = function(mark, motion)
    local new_pos

    -- modify anchor so it has same indexing as win_set_cursor
    local anchor = { mark.end_row + 1, mark.end_col }
    if anchor[2] < 0 then
        anchor[2] = 0
    end

    -- perform the motion then get the new cursor position
    api.nvim_win_set_cursor(0, anchor)
    vim.cmd('normal! ' .. motion)
    new_pos = api.nvim_win_get_cursor(0)
    --

    -- HACK cursor doesn't goto the end of line
    -- 1- for <Right> when cursor is on the last-1 and after performing motion
    -- it's position doesn't change we move it last col
    -- caveat: going forward on the last col moves the cursor 1 col left
    -- caveat: for other motions going to end of line we could perform it twice
    local line = api.nvim_buf_get_lines(0, anchor[1] - 1, anchor[1], true)[1]
    if
        new_pos[2] == anchor[2]
        and vim.fn.strdisplaywidth(line) == new_pos[2] + 1
    then
        new_pos[2] = new_pos[2] + 1
    end

    -- Revert back the modified values
    ---@type Match
    local match = {
        s_row = new_pos[1] - 1,
        s_col = new_pos[2] - 1,
        e_row = new_pos[1] - 1,
        e_col = new_pos[2],
    }

    return match
end

--- Moves the selection by vim motion
--- assumes selection length is 1
---@param motion string
S.move_by_motion = function(motion)
    local selections = utils.get_all_selections()
    local main = utils.get_main_selection()

    local new_pos
    for _, selection in pairs(selections) do
        new_pos = get_new_position(selection, motion)
        utils.update_extmark(selection.id, new_pos, utils.namespace.Multi)
    end

    new_pos = get_new_position(main, motion)
    utils.update_extmark(main.id, new_pos, utils.namespace.Main)
    utils.move_cursor { new_pos.s_row + 1, new_pos.s_col + 1 }
end


--- finds index of last  char in a string
--- considers multibyte utf-8 characters
---@param str string
---@return integer last col
local function find_last_mbchar(str)
    local index = #str
    while
        vim.fn.strdisplaywidth(string.sub(str, index, #str)) >= 4
        and index >= 1
        and index <= #str
    do
        index = index - 1
    end
    return index - 1
end

--- Reduces the selections to a single char
---@param before ActionPosition
S.reduce_to_char = function(before)
    local marks = utils.get_all_selections()
    local main = utils.get_main_selection()

    local row
    if before == utils.position.before then
        local text =
            api.nvim_buf_get_text(0, main.row, 0, main.end_row, main.col, {})
        main.end_col = main.col
        main.col = find_last_mbchar(text[1])
        row = main.row
    else
        local text = api.nvim_buf_get_text(
            0,
            main.row,
            main.col,
            main.end_row,
            main.end_col,
            {}
        )
        main.col = find_last_mbchar(text[#text]) + main.col
        row = main.end_row
    end

    utils.move_cursor { row + 1, main.end_col }

    utils.update_extmark(main.id, {
        s_row = row,
        e_row = row,
        s_col = main.col,
        e_col = main.end_col,
    }, utils.namespace.Main)

    for _, mark in pairs(marks) do
        text = api.nvim_buf_get_text(
            0,
            mark.row,
            mark.col,
            mark.end_row,
            mark.end_col,
            {}
        )
        if before == utils.position.before then
            mark.end_col = concatenateCharsStart(text[1])
            row = mark.row
        else
            mark.col = find_last_mbchar(text[#text])
            row = mark.end_row
        end

        utils.update_extmark(mark.id, {
            s_row = row,
            e_row = row,
            s_col = mark.col,
            e_col = mark.end_col,
        }, utils.namespace.Multi)
    end
end

return S
