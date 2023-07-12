---@type Utils
local utils = require 'multicursors.utils'
local api = vim.api

---@class ExtendMode
local E = {}

--- Perform the motion and finds the new range
--- for selection.
--- TODO change anchor when motion passes it
---@param mark any[]
---@param motion string
---@return Match
local get_new_position = function(mark, motion)
    local new_pos

    -- modify float so it has same indexing as win_set_cursor
    local float = { mark[1] + 1, mark[2] - 1 }
    local anchor = { mark[3].end_row, mark[3].end_col }

    if vim.b.MultiCursorAnchorStart then
        anchor = { mark[1], mark[2] }
        float = { mark[3].end_row + 1, mark[3].end_col - 1 }
    end

    -- goes to other end of selection based on anchor
    -- performs the motion then gets the new cursor position
    api.nvim_buf_call(0, function()
        api.nvim_win_set_cursor(0, float)
        vim.cmd('normal! ' .. vim.v.count1 .. motion)
        new_pos = api.nvim_win_get_cursor(0)
    end)

    ---@type Match
    local match = {
        s_row = anchor[1],
        s_col = anchor[2],
        -- revert back the modified values
        e_row = new_pos[1] - 1,
        e_col = new_pos[2] + 1,
    }

    return match
end

--- Extends selections by motion
---@param motion string
local extend_selections = function(motion)
    local marks = utils.get_all_selections(true)
    local main = utils.get_main_selection(true)

    utils.clear_namespace(utils.namespace.Main)
    utils.clear_namespace(utils.namespace.Multi)

    local new_pos
    for _, selection in pairs(marks) do
        new_pos = get_new_position(
            { selection[2], selection[3], selection[4] },
            motion
        )

        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = get_new_position({ main[2], main[3], main[4] }, motion)
    utils.create_extmark(new_pos, utils.namespace.Main)
end

E.h_method = function()
    extend_selections 'h'
end

E.j_method = function()
    extend_selections 'j'
end

E.k_method = function()
    extend_selections 'k'
end

E.l_method = function()
    extend_selections 'l'
end

E.caret_method = function()
    extend_selections '^'
end

E.dollar_method = function()
    extend_selections '$'
end

E.e_method = function()
    extend_selections 'e'
end

E.w_method = function()
    extend_selections 'w'
end

E.b_method = function()
    extend_selections 'b'
end

--- Toggles the anchor position
E.o_method = function()
    local main = utils.get_main_selection(true)
    if vim.b.MultiCursorAnchorStart == true then
        vim.b.MultiCursorAnchorStart = false
        utils.move_cursor { main[2] + 1, main[3] }
        return
    end
    utils.move_cursor { main[4].end_row + 1, main[4].end_col - 1 }
    vim.b.MultiCursorAnchorStart = true
end

return E
