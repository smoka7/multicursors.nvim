local utils = require 'multicursors.utils'
local api = vim.api

local S = {}

---
---@param mark Selection
---@param motion string
local get_new_position = function(mark, motion)
    local new_pos

    -- modify anchor so it has same indexing as win_set_cursor
    local anchor = { mark.end_row + 1, mark.end_col - 1 }
    if anchor[2] < 0 then
        anchor[2] = 0
    end

    -- perform the motion then get the new cursor position
    api.nvim_win_call(0, function()
        api.nvim_win_set_cursor(0, anchor)
        vim.cmd('normal! ' .. motion)
        new_pos = api.nvim_win_get_cursor(0)
    end)

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
    utils.clear_selections()

    local new_pos
    for _, selection in pairs(selections) do
        new_pos = get_new_position(selection, motion)
        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = get_new_position(main, motion)
    utils.create_extmark(new_pos, utils.namespace.Main)
    utils.move_cursor { new_pos.s_row + 1, new_pos.s_col + 1 }
end

---
---@param length integer
S.move_selections_vertical = function(length)
    local marks = utils.get_all_selections()
    local main = utils.get_main_selection()
    utils.clear_selections()

    ---@param mark Selection
    ---@return integer,integer
    local get_position = function(mark)
        local col = mark.col
        local row = mark.row + length
        local buf_length = api.nvim_buf_line_count(0)

        if row < 1 then
            row = 0
        elseif row >= buf_length then
            row = buf_length - 1
        end

        local line_length =
            string.len(api.nvim_buf_get_lines(0, row, row + 1, true)[1])

        if col < 0 then
            col = -1
        elseif col >= line_length then
            col = line_length - 1
        end
        return row, col
    end

    local row, col = get_position(main)
    utils.create_extmark(
        { s_col = col, e_col = col + 1, s_row = row, e_row = row },
        utils.namespace.Main
    )
    utils.move_cursor { row + 1, col + 1 }

    for _, mark in pairs(marks) do
        row, col = get_position(mark)
        utils.create_extmark(
            { s_col = col, e_col = col + 1, s_row = row, e_row = row },
            utils.namespace.Multi
        )
    end
end

---
---@param length integer
S.move_selections_horizontal = function(length)
    local marks = utils.get_all_selections()
    local main = utils.get_main_selection()
    utils.clear_selections()

    ---@param mark Selection
    ---@return integer,integer
    local get_position = function(mark)
        local col = mark.end_col + length - 1
        local row = mark.end_row

        local line =
            string.len(api.nvim_buf_get_lines(0, row, row + 1, true)[1])
        if col < 0 then
            col = -1
        elseif col >= line then
            col = line - 1
        end
        return row, col
    end

    local row, col = get_position(main)
    utils.create_extmark(
        { s_col = col, e_col = col + 1, s_row = row, e_row = row },
        utils.namespace.Main
    )
    utils.move_cursor { row + 1, col + 1 }

    for _, mark in pairs(marks) do
        row, col = get_position(mark)

        utils.create_extmark(
            { s_col = col, e_col = col + 1, s_row = row, e_row = row },
            utils.namespace.Multi
        )
    end
end

return S
