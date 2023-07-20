---@type Utils
local utils = require 'multicursors.utils'
local api = vim.api

local parsers = require 'nvim-treesitter.parsers'

local ts = require 'multicursors.ts'

---@class ExtendMode
local E = {}

---@param a integer[]
---@param b integer[]
---@return boolean
local function smaller(a, b)
    if a[1] < b[1] then
        return true
    end
    if a[1] == b[1] and a[2] <= b[2] then
        return true
    end
    return false
end

--- Perform the motion and finds the new range for selection.
---@param mark Selection
---@param motion string
---@return Match
local get_new_position = function(mark, motion)
    local new_pos

    -- modify float so it has same indexing as win_set_cursor
    local float = { mark.row + 1, mark.col - 1 }
    local anchor = { mark.end_row + 1, mark.end_col - 1 }

    if vim.b.MultiCursorAnchorStart then
        anchor = { mark.row + 1, mark.col - 1 }
        float = { mark.end_row + 1, mark.end_col - 1 }
    end

    -- goes to other end of selection based on anchor
    -- performs the motion then gets the new cursor position
    api.nvim_buf_call(0, function()
        api.nvim_win_set_cursor(0, float)
        vim.cmd('normal! ' .. vim.v.count1 .. motion)
        new_pos = api.nvim_win_get_cursor(0)
    end)

    -- Revert back the modified values
    ---@type Match
    local match = {
        s_row = anchor[1] - 1,
        s_col = anchor[2] + 1,
        e_row = new_pos[1] - 1,
        e_col = new_pos[2] + 1,
    }

    -- INFO we could change the anchor here like how visual mode does it
    -- but for multiple selections is easy to mess up selections
    -- When motion goes past the anchor do not modify the selection
    if
        (smaller(anchor, float) and smaller(new_pos, anchor))
        or (smaller(float, anchor) and smaller(anchor, new_pos))
    then
        match.e_row = float[1] - 1
        match.e_col = float[2] + 1
        api.nvim_win_set_cursor(0, float)
    end

    return match
end

---@type Match[]
local last_selections = {}

--- Saves current selections position
---@param marks Selection[]
---@param main Selection
local function save_history(marks, main)
    last_selections = {}
    for _, mark in pairs(marks) do
        table.insert(last_selections, {
            s_row = mark.row,
            s_col = mark.col,
            e_row = mark.end_row,
            e_col = mark.end_col,
        })
    end
    table.insert(last_selections, {
        s_row = main.row,
        s_col = main.col,
        e_row = main.end_row,
        e_col = main.end_col,
    })

    utils.clear_selections()
end

function E.undo_history()
    if not last_selections or #last_selections == 0 then
        return
    end

    utils.clear_selections()

    for i = 1, #last_selections, 1 do
        utils.create_extmark(last_selections[i], utils.namespace.Multi)
    end

    utils.create_extmark(
        last_selections[#last_selections],
        utils.namespace.Main
    )
end

--- Extends selections by motion
---@param motion string
local extend_selections = function(motion)
    local marks = utils.get_all_selections()
    local main = utils.get_main_selection()

    save_history(marks, main)

    local new_pos
    for _, selection in pairs(marks) do
        new_pos = get_new_position(selection, motion)

        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = get_new_position(main, motion)
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

E.custom_method = function()
    ---@param motion string
    vim.ui.input({ prompt = 'Enter a motion: ' }, function(motion)
        if not motion then
            return
        end
        extend_selections(motion)
    end)
end

--- Toggles the anchor position
E.o_method = function()
    local main = utils.get_main_selection()
    if vim.b.MultiCursorAnchorStart == true then
        vim.b.MultiCursorAnchorStart = false
        utils.move_cursor { main.row + 1, main.col }
        return
    end
    utils.move_cursor { main.end_row + 1, main.end_col - 1 }
    vim.b.MultiCursorAnchorStart = true
end

---@param callback fun(mark:Match):Match
local extend_selections_ts = function(callback)
    if not parsers.has_parser() then
        return
    end
    local marks = utils.get_all_selections()
    local main = utils.get_main_selection()

    save_history(marks, main)

    local new_pos
    for _, selection in pairs(marks) do
        new_pos = callback {
            s_row = selection.row,
            s_col = selection.col,
            e_row = selection.end_row,
            e_col = selection.end_col,
        }
        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = callback {
        s_row = main.row,
        s_col = main.col,
        e_row = main.end_row,
        e_col = main.end_col,
    }
    utils.create_extmark(new_pos, utils.namespace.Main)
end

E.node_parent = function()
    extend_selections_ts(ts.extend_node)
end

E.node_first_child = function()
    extend_selections_ts(ts.get_first_child)
end

E.node_last_child = function()
    extend_selections_ts(ts.get_last_child)
end

return E
