local utils = require 'multicursors.utils'
local api = vim.api

local S = {}

---
---@param selection Selection
---@param motion string
---@return Selection
S._get_new_position = function(selection, motion)
    local new_pos

    -- INFO for extmarks before start of lines nvim changes the col value
    -- to line length so we have to zero it ourself
    if
        selection.row == selection.end_row
        and selection.col > selection.end_col
    then
        selection.col = -1
    end

    -- modify anchor so it has same indexing as win_set_cursor
    local anchor = { selection.end_row + 1, selection.col + 1 }
    if anchor[2] < 0 then
        anchor[2] = 0
    end

    -- perform the motion then get the new cursor position
    api.nvim_win_set_cursor(0, anchor)
    vim.cmd('normal! ' .. motion)
    new_pos = api.nvim_win_get_cursor(0)

    -- Revert back the modified values
    selection.row = new_pos[1] - 1
    selection.col = new_pos[2] - 1
    selection.end_row = new_pos[1] - 1
    selection.end_col = new_pos[2]

    return selection
end

--- Gets the text before, on or after a selection
---@param selection Selection
---@param pos ActionPosition
---@return string
local get_selection_content = function(selection, pos)
    local lines =
        api.nvim_buf_get_lines(0, selection.row, selection.end_row + 1, false)

    -- From start of  first line till start of selection
    if pos == utils.position.before then
        return lines[1]:sub(0, selection.col)

    -- From start of last line till end of selection
    elseif pos == utils.position.on then
        return lines[#lines]:sub(0, selection.end_col)
    end

    -- From end of selection till end of line
    return lines[#lines]:sub(selection.end_col + 1)
end

--- returns byte index of last char in text
---@param text string
---@return integer
local function find_last_char_byte_idx(text)
    local charlen = vim.fn.strcharlen(text)
    return vim.fn.byteidx(text, charlen - 1) or -1
end

--- Reduces the selection to the char before it
---@param selection Selection
---@param text string content of selection
---@return Selection
local function reduce_to_before(selection, text)
    -- selection is at start of line
    if
        selection.col >= selection.end_col
        and selection.end_col == 0
        and selection.row == selection.end_row
    then
        selection.col = -1
    else
        selection.end_col = selection.col
        selection.col = find_last_char_byte_idx(text)
        selection.end_row = selection.row
    end
    return selection
end

--- Reduces the selection to last char of it
---@param selection Selection
---@param text string content of selection
---@return Selection
local function reduce_to_last(selection, text)
    selection.col = find_last_char_byte_idx(text)
    selection.row = selection.end_row
    return selection
end

--- Reduces the selection to the char of it
---@param selection Selection
---@param text string content of selection
---@param count integer count of chars
---@return Selection
local function reduce_to_after(selection, text, count)
    -- at the EOL do not move
    if #text == 0 then
        return selection
    end
    selection.col = selection.end_col
    selection.end_col = vim.fn.byteidx(text, count) + selection.end_col
    selection.row = selection.end_row
    return selection
end

--- Reduces a selection to a char in position
---@param selection Selection
---@param pos ActionPosition
---@param count integer?
---@return Selection
S._get_reduced_selection = function(selection, pos, count)
    local text = get_selection_content(selection, pos)
    if pos == utils.position.before then
        selection = reduce_to_before(selection, text)
    elseif pos == utils.position.on then
        selection = reduce_to_last(selection, text)
    else
        selection = reduce_to_after(selection, text, count or 1)
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
        new_pos = S._get_new_position(selection, motion)
        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = S._get_new_position(main, motion)

    utils.create_extmark(new_pos, utils.namespace.Main)
    utils.move_cursor { new_pos.row + 1, new_pos.col + 1 }
end

--- Reduces the selections to a single char
---@param pos ActionPosition
S.reduce_to_char = function(pos)
    local selctions = utils.get_all_selections()
    local main = utils.get_main_selection()

    main = S._get_reduced_selection(main, pos)
    utils.move_cursor { main.row + 1, main.end_col }

    utils.create_extmark(main, utils.namespace.Main)

    for _, selection in pairs(selctions) do
        main = S._get_reduced_selection(selection, pos)
        utils.create_extmark(selection, utils.namespace.Multi)
    end
end

--- Moves the selections forward
---@param count integer
S._move_forward = function(count)
    local selctions = utils.get_all_selections()
    local main = utils.get_main_selection()

    main = S._get_reduced_selection(main, utils.position.after, count)
    utils.move_cursor { main.row + 1, main.end_col }

    utils.create_extmark(main, utils.namespace.Main)

    for _, selection in pairs(selctions) do
        main = S._get_reduced_selection(selection, utils.position.after, count)
        utils.create_extmark(selection, utils.namespace.Multi)
    end
end

---@param pos ActionPosition
S.move_char_horizontal = function(pos)
    local selections = utils.get_all_selections()
    local main = utils.get_main_selection()

    local new
    for _, selection in pairs(selections) do
        new = S._get_reduced_selection(selection, pos)
        utils.create_extmark(new, utils.namespace.Multi)
    end

    new = S._get_reduced_selection(main, pos)
    utils.create_extmark(new, utils.namespace.Main)
    utils.move_cursor { new.row + 1, new.end_col }
end

return S
