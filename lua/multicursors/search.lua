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
        s_row = cursor[1] - 1,
        s_col = left[2],
        e_col = right[3] + cursor[2],
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
        utils.move_cursor { all[#all].s_row, all[#all].e_col }
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
---@param offset integer
---@return Match?
S.find_next_match = function(string, pattern, offset)
    if string == '' then
        return
    end

    local match = vim.fn.matchstrpos(string, '\\<' .. pattern .. '\\>', offset)
    -- -1 range means not found
    if match[2] == -1 and match[3] == -1 then
        return
    end

    --- @type Match
    local found = {
        s_col = match[2],
        e_col = match[3],
    }

    return found
end

--- Returns the last match before the cursor
---@param string string
---@param pattern string
---@param till integer
---@return Match?
S.find_prev_match = function(string, pattern, till)
    if string == '' then
        return
    end

    if till ~= -1 then
        string = string:sub(0, till)
    end

    ---@type any[]
    local match = {}
    local found = nil ---@type Match?

    repeat
        match =
            vim.fn.matchstrpos(string, '\\<' .. pattern .. '\\>', match[3] or 0)
        if match[2] ~= -1 and match[3] ~= -1 then
            found = {
                s_col = match[2],
                e_col = match[3],
            }
        end
    until match and match[2] == -1 and match[3] == -1

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

    utils.mark_found_match({ s_row = row, s_col = col, e_col = finish }, skip)
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
    utils.mark_found_match({ s_row = row, s_col = col, e_col = finish }, skip)
end

--- Finds the actual row,col for start and end of match
---@param text string
---@param start integer
---@param end_ integer
---@return Match
local find_real_match = function(text, start, end_)
    -- Count newlines and characters to get the bounds
    local row, col = 0, 0
    for i = 1, start do
        if text:sub(i, i) == '\n' then
            row = row + 1
            col = 0
        else
            col = col + 1
        end
    end
    --

    ---@type Match
    local match = {
        s_row = row + 1,
        s_col = col - 1,
    }

    -- Count till finish
    for i = start, end_ do
        if text:sub(i, i) == '\n' then
            row = row + 1
            col = 0
        else
            col = col + 1
        end
    end

    match.e_col = col
    match.e_row = row + 1

    return match
end

--- Finds first match of the pattern in text
---@param text string
---@param pattern string
---@return Match?
S.find_first_multiline = function(text, pattern)
    local start, end_ = text:find(pattern)
    if not start or not end_ then
        return
    end

    return find_real_match(text, start, end_)
end

--- Finds last match of the pattern in text
---@param text string
---@param pattern string
---@return Match?
S.find_last_multiline = function(text, pattern)
    local s, f, start, end_
    local offset = 0
    repeat
        s, f = text:find(pattern, offset)
        if s and f then
            start = s
            end_ = f
            offset = f
        end
    until not s or not f

    if not start or not end_ then
        return
    end

    return find_real_match(text, start, end_)
end

--- Gets the buffer text after or before the cursor
--- concatenates lines with `\n`
---@param pos ActionPosition
---@return string
S.merge_buffer_text = function(pos)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local cursor = api.nvim_win_get_cursor(0)

    if pos == utils.position.after then
        return lines[cursor[1]]:sub(cursor[2] + 2, -1)
            .. '\n'
            .. table.concat(lines, '\n', cursor[1] + 1)
    end

    return lines[cursor[1]]:sub(cursor[2], -1)
        .. '\n'
        .. table.concat(lines, '\n', cursor[1], #lines)
end

--- Searches for multi line pattern in buffer
---@param pattern string
---@param pos ActionPosition
S.multiline_string = function(pattern, pos)
    local text = S.merge_buffer_text(pos)

    if pos == utils.position.after then
        return S.find_first_multiline(text, pattern)
    end

    return S.find_last_multiline(text, pattern)
end

return S
