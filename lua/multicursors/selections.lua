local utils = require 'multicursors.utils'
local api = vim.api

local S = {}

---
---@param selection Selection
---@param motion string
---@return Selection
local get_new_position = function(selection, motion)
    local new_pos

    -- modify anchor so it has same indexing as win_set_cursor
    local anchor = { selection.end_row + 1, selection.end_col }
    if anchor[2] < 0 then
        anchor[2] = 0
    end

    -- perform the motion then get the new cursor position
    api.nvim_win_set_cursor(0, anchor)
    vim.cmd('normal! ' .. motion)
    new_pos = api.nvim_win_get_cursor(0)

    -- HACK cursor doesn't goto the end of line
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
    selection.row = new_pos[1] - 1
    selection.col = new_pos[2] - 1
    selection.end_row = new_pos[1] - 1
    selection.end_col = new_pos[2]

    return selection
end

--- finds index of last  char in a string
--- considers multibyte utf-8 characters
---@param str string
---@return integer last col
local function find_first_char(str)
    local index = 1
    while
        vim.fn.strdisplaywidth(string.sub(str, 0, index)) >= 4
        and index >= 1
        and index <= #str
    do
        index = index + 1
    end
    return index
end

--- finds index of last  char in a string
--- considers multibyte utf-8 characters
---@param str string
---@return integer last col
local function find_last_char(str)
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

--- Gets the text before, on or after a selection
---@param selection Selection
---@param pos ActionPosition
---@return string
local get_selection_context = function(selection, pos)
    if pos == utils.position.before then
        --HACK when selection is at first of line return empty text
        -- otherwise it wraps around the line
        -- why selection.col is at end of line??
        if selection.end_col == 0 then
            return ''
        end

        return api.nvim_buf_get_text(
            0,
            selection.row,
            0,
            selection.row,
            selection.col,
            {}
        )[1]
    elseif pos == utils.position.on then
        return api.nvim_buf_get_text(
            0,
            selection.end_row,
            0,
            selection.end_row,
            selection.end_col,
            {}
        )[1]
    end

    return string.sub(
        api.nvim_buf_get_lines(
            0,
            selection.end_row,
            selection.end_row + 1,
            false
        )[1],
        selection.end_col + 1
    )
end

--- Reduces a selection to a char in position
---@param selection Selection
---@param pos ActionPosition
---@return Selection
local get_reduced_selection = function(selection, pos)
    local text = get_selection_context(selection, pos)

    if pos == utils.position.before then
        selection.end_col = selection.col
        selection.col = find_last_char(text)
        selection.end_row = selection.row
    elseif pos == utils.position.on then
        selection.col = find_last_char(text)
        selection.row = selection.end_row
    else
        -- at the EOL do not move
        if #text ~= 0 then
            selection.col = selection.end_col
            selection.end_col = find_first_char(text) + selection.end_col
            selection.row = selection.end_row
        end
    end
    return selection
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
        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = get_new_position(main, motion)

    utils.create_extmark(new_pos, utils.namespace.Main)
    utils.move_cursor { new_pos.row + 1, new_pos.col + 1 }
end

--- Reduces the selections to a single char
---@param pos ActionPosition
S.reduce_to_char = function(pos)
    local selctions = utils.get_all_selections()
    local main = utils.get_main_selection()

    main = get_reduced_selection(main, pos)
    utils.move_cursor { main.row + 1, main.end_col }

    utils.create_extmark(main, utils.namespace.Main)

    for _, selection in pairs(selctions) do
        main = get_reduced_selection(selection, pos)
        utils.create_extmark(selection, utils.namespace.Multi)
    end
end

---@param pos ActionPosition
S.move_char_horizontal = function(pos)
    local selections = utils.get_all_selections()
    local main = utils.get_main_selection()

    local new
    for _, selection in pairs(selections) do
        new = get_reduced_selection(selection, pos)
        utils.create_extmark(new, utils.namespace.Multi)
    end

    new = get_reduced_selection(main, pos)
    utils.create_extmark(new, utils.namespace.Main)
    utils.move_cursor { new.row + 1, new.end_col }
end

return S
