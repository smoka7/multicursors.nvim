---@type Utils
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

    utils.create_extmark({
        s_row = cursor[1] - 1,
        e_row = cursor[1] - 1,
        s_col = left[2],
        e_col = right[3] + cursor[2],
    }, utils.namespace.Main)
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
                s_col = match[2] + start_col,
                e_col = match[3] + start_col,
                s_row = start_row,
                e_row = start_row,
            }
        end
    until match and match[2] == -1 and match[3] == -1

    match = {}
    for i = 2, #content, 1 do
        repeat
            match = vim.fn.matchstrpos(content[i], pattern, match[3] or 0)
            if match[2] ~= -1 and match[3] ~= -1 then
                all[#all + 1] = {
                    s_col = match[2],
                    e_col = match[3],
                    s_row = start_row + i - 1,
                    e_row = start_row + i - 1,
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
---@param ctx SearchContext
---@return Match? found
S.find_next_match = function(ctx)
    if ctx.text == '' then
        return
    end

    local match =
        vim.fn.matchstrpos(ctx.text, '\\<' .. ctx.pattern .. '\\>', ctx.offset)
    -- -1 range means not found
    if match[2] == -1 and match[3] == -1 then
        return
    end

    --- @type Match
    return {
        s_col = match[2],
        e_col = match[3],
        s_row = ctx.row - 1,
        e_row = ctx.row - 1,
    }
end

--- Finds next match and marks it
---@param skip boolean
---@return Match? next next Match
S.find_next = function(skip)
    ---@type SearchContext
    local ctx = {
        pattern = vim.b.MultiCursorPattern,
        skip = skip,
    }

    if not ctx.pattern or ctx.pattern == '' then
        return
    end

    if vim.b.MultiCursorMultiline then
        local match = S.multiline_string(ctx.pattern, utils.position.after)
        if match then
            return match
        end
    end

    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1]
    local column = cursor[2] + 1
    local buffer = api.nvim_buf_get_lines(0, 0, -1, true)

    -- Search the cursor line from cursor column
    ctx.text = buffer[row_idx]
    ctx.offset = column
    ctx.row = row_idx

    local match = S.find_next_match(ctx)
    if match then
        return match
    end
    ---

    -- search from cursor to end of buffer for pattern
    ctx.offset = 0
    for idx = row_idx + 1, line_count, 1 do
        ctx.text = buffer[idx]
        ctx.row = idx
        match = S.find_next_match(ctx)
        if match then
            return match
        end
    end
    --

    -- At end wrap around the buffer when we can't match anything
    for idx = 1, row_idx + 1, 1 do
        ctx.text = buffer[idx]
        ctx.row = idx
        match = S.find_next_match(ctx)
        if match then
            return match
        end
    end
end

--- Returns the last match before the cursor
---@param ctx SearchContext
---@return Match? found
S.find_prev_match = function(ctx)
    if ctx.text == '' then
        return
    end

    if ctx.till ~= -1 then
        ctx.text = ctx.text:sub(0, ctx.till)
    end

    ---@type any[]
    local match = {}
    local found = nil ---@type Match?

    repeat
        match = vim.fn.matchstrpos(
            ctx.text,
            '\\<' .. ctx.pattern .. '\\>',
            match[3] or 0
        )
        if match[2] ~= -1 and match[3] ~= -1 then
            found = {
                s_col = match[2],
                e_col = match[3],
            }
        end
    until match and match[2] == -1 and match[3] == -1

    if not found then
        return
    end

    found.s_row = ctx.row - 1
    found.e_row = ctx.row - 1

    return found
end

--- Finds last match before cursor
---@param skip boolean
---@return Match? last match
S.find_prev = function(skip)
    ---@type SearchContext
    local ctx = {
        pattern = vim.b.MultiCursorPattern,
        skip = skip,
    }

    if not ctx.pattern or ctx.pattern == '' then
        return
    end

    if vim.b.MultiCursorMultiline then
        return S.multiline_string(ctx.pattern, utils.position.before)
    end

    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1]
    local column = cursor[2]
    local buffer = api.nvim_buf_get_lines(0, 0, -1, true)

    -- search the cursor line till cursor column
    ctx.text = buffer[row_idx]
    ctx.till = column
    ctx.row = row_idx

    local match = S.find_prev_match(ctx)
    if match then
        return match
    end
    --

    -- search from cursor to start of buffer
    ctx.till = -1
    for idx = row_idx - 1, 1, -1 do
        ctx.text = buffer[idx]
        ctx.row = idx
        match = S.find_prev_match(ctx)
        if match then
            return match
        end
    end
    --

    -- At end wrap around the buffer when we can't match anything
    for idx = line_count, row_idx, -1 do
        ctx.text = buffer[idx]
        ctx.row = idx
        match = S.find_prev_match(ctx)
        if match then
            return match
        end
    end
end

--- Selects the char under the cursor as main selection
S.new_under_cursor = function()
    local cursor = api.nvim_win_get_cursor(0)

    ---@type Match
    local match = {
        s_row = cursor[1] - 1,
        e_row = cursor[1] - 1,
        s_col = cursor[2],
        e_col = cursor[2] + 1,
    }

    if match.s_col == 0 then
        match.e_col = 0
    end

    vim.b.MultiCursorPattern = ''
    -- vim remembers the first column when moving verticaly
    vim.b.MultiCursorColumn = cursor[2]
    utils.create_extmark(match, utils.namespace.Main)
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

    utils.mark_found_match(
        { s_row = row, e_row = row, s_col = col, e_col = finish },
        skip
    )
    utils.move_cursor({ row + 1, col }, nil)
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
    utils.mark_found_match(
        { s_row = row, e_row = row, s_col = col, e_col = finish },
        skip
    )
    utils.move_cursor({ row + 1, col }, nil)
end

--- Searches for multi line pattern in buffer
---@param pattern string
---@param pos ActionPosition
---@return Match?
S.multiline_string = function(pattern, pos)
    local s, e
    if pos == utils.position.after then
        e = vim.fn.searchpos(pattern, 'wzen')
        s = vim.fn.searchpos(pattern, 'wzn')
        if s[1] == 0 and s[1] == 0 then
            return
        end
    elseif pos == utils.position.before then
        e = vim.fn.searchpos(pattern, 'bwzen')
        s = vim.fn.searchpos(pattern, 'bwzn')
        if s[1] == 0 and s[1] == 0 then
            return
        end
    else
        e = vim.fn.searchpos(pattern, 'wzecn')
        s = vim.fn.searchpos(pattern, 'wzcn')
        if s[1] == 0 and s[1] == 0 then
            return
        end
    end

    local match = {
        s_row = s[1] - 1,
        s_col = s[2] - 1,
        e_row = e[1] - 1,
        e_col = e[2],
    }

    return match
end

--- Searches for a pattern across buffer and creates
--- a selection for every match
---@param whole_buffer boolean
S.find_pattern = function(whole_buffer)
    local content

    if whole_buffer then
        content = api.nvim_buf_get_lines(0, 0, -1, true)
    else
        content = utils.get_last_visual_range()
    end

    if #content == 0 then
        vim.notify('buffer or visual selection is empty', vim.log.levels.WARN)
        return
    end

    api.nvim_echo({}, false, {})
    api.nvim_echo({ { 'enter a pattern : ' } }, false, {})

    local pattern = ''
    local ESC = api.nvim_replace_termcodes('<Esc>', true, false, true)
    local CR = api.nvim_replace_termcodes('<cr>', true, false, true)
    local BS = api.nvim_replace_termcodes('<bs>', true, false, true)
    while true do
        local key = utils.get_char()
        if not key then
            utils.exit()
            return
        end

        if key == ESC or key == CR then
            break
        end

        if key == BS and #pattern then
            pattern = pattern:sub(0, #pattern - 1)
        else
            pattern = pattern .. key
        end

        vim.b.MultiCursorPattern = pattern
        --clear the old selection every key press
        utils.clear_selections()

        api.nvim_echo({}, false, {})
        api.nvim_echo({ { 'enter a pattern : ' .. pattern } }, false, {})

        if pattern ~= '' then
            if not whole_buffer then
                local start = api.nvim_buf_get_mark(0, '<')
                S.find_all_matches(content, pattern, start[1] - 1, start[2])
            else
                S.find_all_matches(content, pattern, 0, 0)
            end
            vim.b.MultiCursorPattern = pattern
        end
    end
end

--- Selects the text in visual mode
S.find_selected = function()
    -- Exit out of visual mode
    api.nvim_feedkeys(
        api.nvim_replace_termcodes('<Esc>', false, true, true),
        'nx',
        false
    )

    -- Gets the range of last selected text
    --- FIXME multibyte characters doesn't get picked correctly
    local lines = utils.get_last_visual_range()

    -- when this command gets executed from a mapping it finds the next
    -- match so we go to start of selection to find the selected text first
    local start = api.nvim_buf_get_mark(0, '<')
    utils.move_cursor { start[1], start[2] }

    -- joins the selected case with newlines
    -- and searches for it
    local pattern = table.concat(lines, '\\n')
    local match = S.multiline_string(pattern, utils.position.on)
    if not match then
        return
    end

    vim.b.MultiCursorPattern = pattern
    vim.b.MultiCursorMultiline = true

    utils.create_extmark(match, utils.namespace.Main)
    utils.move_cursor { match.e_row + 1, match.e_col + 1 }
end

return S
