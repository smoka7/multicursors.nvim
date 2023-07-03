local utils = require 'multicursors.utils'
local api = vim.api
local S = {}

---
---@param match Match match to mark
---@param skip boolean wheter or not skip current match
local mark_found_match = function(match, skip)
    -- first clear the main selection
    -- then create a selection in place of main one
    local main = utils.get_main_selection(true)
    utils.clear_namespace(utils.namespace.Main)

    if not skip then
        utils.create_extmark(
            { row = main[2], start = main[3], finish = main[4].end_col },
            utils.namespace.Multi
        )
    end
    --create the main selection
    utils.create_extmark(match, utils.namespace.Main)
    --deletes the selection when there was a selection there
    utils.delete_extmark(match, utils.namespace.Multi)

    utils.move_cursor({ match.row + 1, match.start }, nil)
end

--- finds the word under the cursor
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

--- finds and marks all matches of a pattern in content
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

    mark_found_match(found, skip)

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

    mark_found_match(found, skip)
    return found
end

return S
