local utils = require 'multicursors.utils'
local api = vim.api

---@class Search
local S = {}

--- Finds the word under the cursor
---@return Match?
S.find_cursor_word = function()
    local line = api.nvim_get_current_line()
    if not line then
        return
    end

    local cursor = api.nvim_win_get_cursor(0)
    local left = vim.fn.matchstrpos(line:sub(1, cursor[2] + 1), [[\k*$]])
    local right = vim.fn.matchstrpos(line:sub(cursor[2] + 1), [[^\k*]])

    if left == -1 and right == -1 then
        return
    end

    vim.b.MultiCursorPattern = left[1] .. right[1]:sub(2)
    return {
        row = cursor[1] - 1,
        start = left[2],
        finish = right[3] + cursor[2],
    }
end

--- Finds and marks all matches of a pattern in content
---@param content string[]
---@param pattern string
---@param start_row integer row offset in case of searching in a visual range
---@param start_col integer column offset in case of searching in a visual range
S.find_all_matches = function(content, pattern, start_row, start_col)
    ---@type Match[]
    local all = {}
    local match = {}
    -- we have to add start_col as offset to first line
    repeat
        match = vim.fn.matchstrpos(content[1], pattern, match[3] or 0)
        if match[2] ~= -1 and match[3] ~= -1 then
            all[#all + 1] = {
                start = match[2] + start_col,
                finish = match[3] + start_col,
                row = start_row,
            }
        end
    until match and match[2] == -1 and match[3] == -1

    match = {}
    for i = 2, #content, 1 do
        repeat
            match = vim.fn.matchstrpos(content[i], pattern, match[3] or 0)
            if match[2] ~= -1 and match[3] ~= -1 then
                all[#all + 1] = {
                    start = match[2],
                    finish = match[3],
                    row = start_row + i - 1,
                }
            end
        until match and match[2] == -1 and match[3] == -1
    end

    if #all > 0 then
        -- make last match the main one
        utils.create_extmark(all[#all], utils.namespace.Main)
        utils.move_cursor { all[#all].row, all[#all].finish }
    else
        vim.notify 'no match found'
    end

    if #all > 1 then
        for i = 1, #all - 1, 1 do
            utils.create_extmark(all[i], utils.namespace.Multi)
        end
    end
end

--- Returns the first match for pattern after a offset in a string
---@param string string
---@param row_idx integer
---@param offset integer
---@param skip boolean
---@return Match?
S.find_next_match = function(string, row_idx, offset, skip)
    if string == '' then
        return
    end

    local pattern = vim.b.MultiCursorPattern

    local match = vim.fn.matchstrpos(string, '\\<' .. pattern .. '\\>', offset)
    -- -1 range means not found
    if match[2] == -1 and match[3] == -1 then
        return
    end

    --- @class Match
    local found = {
        start = match[2],
        finish = match[3],
        row = row_idx,
    }

    utils.mark_found_match(found, skip)

    return found
end

--- Returns the last match before the cursor
---@param string string
---@param row_idx integer
---@param till integer
---@param skip boolean
---@return Match?
S.find_prev_match = function(string, row_idx, till, skip)
    if string == '' then
        return
    end

    if till ~= -1 then
        string = string:sub(0, till)
    end

    ---@type any[]
    local match = {}
    local found = nil ---@type Match?
    local pattern = vim.b.MultiCursorPattern
    repeat
        match =
            vim.fn.matchstrpos(string, '\\<' .. pattern .. '\\>', match[3] or 0)
        if match[2] ~= -1 and match[3] ~= -1 then
            found = {
                start = match[2],
                finish = match[3],
                row = row_idx,
            }
        end
    until match and match[2] == -1 and match[3] == -1

    if not found then
        return
    end

    utils.mark_found_match(found, skip)
    return found
end

--- Creates a selection on the char below the cursor
---@param skip boolean skips the current selection
S.create_down = function(skip)
    local cursor = api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local col = vim.b.MultiCursorColumn
    if not col then
        col = cursor[2] - 1
        vim.b.MultiCursorColumn = col
    end

    local buf_count = api.nvim_buf_line_count(0)
    if row >= buf_count then
        return
    end

    local row_text = api.nvim_buf_get_lines(0, row, row + 1, true)[1]
    if col > #row_text then
        col = #row_text - 1
    end

    local finish = col + 1
    if #row_text == 0 then
        col = 0
        finish = 0
    end

    utils.mark_found_match({ row = row, start = col, finish = finish }, skip)
end

--- Creates a selection on the char above the cursor
---@param skip boolean skips the current selection
S.create_up = function(skip)
    local cursor = api.nvim_win_get_cursor(0)
    local row = cursor[1] - 2
    local col = vim.b.MultiCursorColumn
    if not col then
        col = cursor[2] - 1
        vim.b.MultiCursorColumn = col
    end

    if row < 0 then
        return
    end

    local row_text = api.nvim_buf_get_lines(0, row, row + 1, true)[1]
    if col >= #row_text then
        col = #row_text - 1
    end

    local finish = col + 1
    if #row_text == 0 then
        col = 0
        finish = 0
    end
    utils.mark_found_match({ row = row, start = col, finish = finish }, skip)
end

return S
