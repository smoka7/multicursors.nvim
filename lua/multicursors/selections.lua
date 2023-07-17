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
end

return S
