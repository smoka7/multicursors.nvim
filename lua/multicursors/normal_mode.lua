local api = vim.api

---@class Utils
local utils = require 'multicursors.utils'

---@class InsertMode
local insert_mode = require 'multicursors.insert_mode'

local debug = utils.debug

local ns_id = api.nvim_create_namespace 'multicursors'
local main_cursor = api.nvim_create_namespace 'multicursorsmaincursor'
local ESC = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)

---@class NormalMode
local M = {}

--- Returns the first match for pattern after a offset in a string
---@param string string
---@param last_match Match
---@param row_idx integer
---@param offset integer
---@param skip boolean
---@return Match?
local find_next_match = function(string, last_match, row_idx, offset, skip)
    if not string or string == '' then
        return
    end

    if offset ~= 0 then
        string = string:sub(offset + 1, -1)
    end

    local match =
        vim.fn.matchstrpos(string, '\\<' .. last_match.pattern .. '\\>')
    -- -1 range means not found
    if match[2] == -1 and match[3] == -1 then
        return
    end

    --- @class Match
    local found = { pattern = last_match.pattern }

    -- add offset to match position index
    found.start = match[2] + offset
    found.finish = match[3] + offset
    found.row = row_idx

    -- jump the cursor to last match
    api.nvim_buf_clear_namespace(0, main_cursor, 0, -1)
    if not skip then
        utils.create_extmark(last_match, ns_id)
    end
    utils.create_extmark(found, main_cursor)
    utils.move_cursor({ row_idx, found.start }, nil)

    return found
end
--
-- creates a mark for word under the cursor
---@return Match?
M.find_cursor_word = function()
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
    local match = {
        row = cursor[1],
        start = left[2],
        finish = right[3] + cursor[2],
        pattern = left[1] .. right[1]:sub(2),
    }
    utils.create_extmark(match, main_cursor)
    return match
end

---finds next match and marks it
---@param last_match Match?
---@param skip boolean
---@return Match? next next Match
M.find_next = function(last_match, skip)
    if not last_match then
        return
    end
    local line_count = api.nvim_buf_line_count(0)
    local row_idx = last_match.row
    local column = last_match.finish

    -- search the same line as cursor with cursor col as offset cursor
    local line = api.nvim_buf_get_lines(0, row_idx - 1, row_idx, true)[1]
    local match = find_next_match(line, last_match, row_idx, column, skip)
    if match then
        return match
    end

    -- search from cursor to end of buffer for pattern
    for idx = row_idx + 1, line_count, 1 do
        line = api.nvim_buf_get_lines(0, idx - 1, idx, true)[1]
        match = find_next_match(line, last_match, idx, 0, skip)
        if match then
            return match
        end
    end

    -- when we didn't find the pattern we start searching again
    -- from start of the buffer
    for idx = 0, row_idx, 1 do
        line = api.nvim_buf_get_lines(0, idx - 1, idx, true)[1]
        match = find_next_match(line, last_match, idx, 0, skip)
        if match then
            return match
        end
    end
end

M.start = function()
    local last_mark = M.find_cursor_word()

    --TODO when nil just add the cursor???
    if not last_mark then
        return
    end
    debug 'listening for mod selector'
    M.listen(last_mark)
end

---@param last_mark? Match
M.listen = function(last_mark)
    while true do
        local key = utils.get_char()
        if not key then
            utils.exit()
            return
        end

        if key == ESC then
            utils.exit()
            return
        elseif key == 'n' then
            last_mark = M.find_next(last_mark, false)
        elseif key == 'q' then
            last_mark = M.find_next(last_mark, true)
        elseif key == 'i' then
            api.nvim_feedkeys('i', 't', false)
            insert_mode.start()
            -- not returning causes infinite loop
            return
        elseif key == 'a' then
            api.nvim_feedkeys('i', 't', false)
            insert_mode.append()
            return
        elseif key == 'c' then
            --M.change()
            return
        end
    end
end
return M
