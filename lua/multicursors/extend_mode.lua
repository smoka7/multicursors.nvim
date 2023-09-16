local utils = require 'multicursors.utils'
local api = vim.api

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
---@return Selection,integer
local get_new_position = function(mark, motion)
    local new_pos

    -- modify float so it has same indexing as win_set_cursor
    local float = { mark.row + 1, mark.col }
    local anchor = { mark.end_row + 1, mark.end_col }

    --- decrement end_col value so we go to last char of selection
    if vim.b.MultiCursorAnchorStart then
        anchor = { mark.row + 1, mark.col }
        float = { mark.end_row + 1, mark.end_col - 1 }
    end

    -- Extending to a empty line results to a negative col value
    -- that we cannot jump to so we make it zero
    if float[2] < 0 then
        float[2] = 0
    end

    -- goes to other end of selection based on anchor
    -- performs the motion then gets the new cursor position
    api.nvim_win_set_cursor(0, float)
    vim.cmd('normal! ' .. vim.v.count1 .. motion)
    new_pos = api.nvim_win_get_cursor(0)

    -- Revert back the modified values
    ---@type Selection
    local match = {
        id = mark.id,
        row = anchor[1] - 1,
        col = anchor[2],
        end_row = new_pos[1] - 1,
        end_col = new_pos[2],
    }

    -- Anchor is at start and new position passes it
    local passed_start = vim.b.MultiCursorAnchorStart
        and smaller(anchor, float)
        and smaller(new_pos, anchor)
        and math.abs(new_pos[2] - anchor[2]) >= 1

    -- Anchor is at the end and new position passes it
    local passed_end = not vim.b.MultiCursorAnchorStart
        and smaller(float, anchor)
        and smaller(anchor, new_pos)
        and math.abs(new_pos[2] - anchor[2]) >= 0

    local passed = 0
    if passed_start or passed_end then
        passed = 1
    end

    -- Up we decremented end_col value for forward extends
    if vim.b.MultiCursorAnchorStart or passed_end then
        match.end_col = match.end_col + 1
    end

    -- check for empty lines
    local line =
        api.nvim_buf_get_lines(0, match.end_row, match.end_row + 1, false)
    if #line[1] == 0 then
        match.end_col = 0
    end

    return match, passed
end

---@type Selection[]
local last_selections = {}

--- Saves current selections position
---@param marks Selection[]
---@param main Selection
local function save_history(marks, main)
    last_selections = {}

    for _, value in pairs(marks) do
        last_selections[#last_selections + 1] = value
    end

    last_selections[#last_selections + 1] = main
end

function E.undo_history()
    if not last_selections or #last_selections == 0 then
        return
    end

    utils.clear_selections()

    for i = 1, #last_selections - 1, 1 do
        utils.create_extmark(last_selections[i], utils.namespace.Multi)
    end

    utils.create_extmark(
        last_selections[#last_selections],
        utils.namespace.Main
    )
    last_selections = {}
end

--- Extends selections by motion
---@param motion string
local function extend_selections(motion)
    local selections = utils.get_all_selections()
    local main = utils.get_main_selection()

    save_history(selections, main)

    local new_pos, passed
    local passed_count = 0
    for _, selection in pairs(selections) do
        new_pos, passed = get_new_position(selection, motion)
        passed_count = passed_count + passed
        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos, passed = get_new_position(main, motion)
    passed_count = passed_count + passed
    utils.create_extmark(new_pos, utils.namespace.Main)

    -- When every extension results in passing the anchor
    -- toggle the anchor to copy visual mode behavior
    if passed_count == #selections + 1 then
        E.o_method()
    end
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

---@param callback fun(mark:Selection):Selection
local extend_selections_ts = function(callback)
    local marks = utils.get_all_selections()
    local main = utils.get_main_selection()

    save_history(marks, main)

    local new_pos
    for _, selection in pairs(marks) do
        new_pos = callback {
            row = selection.row,
            col = selection.col,
            end_row = selection.end_row,
            end_col = selection.end_col,
        }
        utils.create_extmark(new_pos, utils.namespace.Multi)
    end

    new_pos = callback {
        row = main.row,
        col = main.col,
        end_row = main.end_row,
        end_col = main.end_col,
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
