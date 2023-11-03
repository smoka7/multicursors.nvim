---@type Utils
local utils = require 'multicursors.utils'
local api = vim.api

---@class Search
local S = {}

--- Return last index of a pattern in string
---@param pattern string
---@param str string
---@return integer
local function find_last_index(pattern, str)
    local index = 0
    local startPos = 1

    repeat
        local matchStart, matchEnd = string.find(str, pattern, startPos)
        if matchStart then
            index = matchStart
            startPos = matchEnd + 1
        end
    until not matchStart

    return index
end

--- Finds the word under the cursor
--- @return true? returns true if it creates a selection
S.find_cursor_word = function()
    vim.b.MultiCursorPattern = ''
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

    local pattern = left[1] .. right[1]:sub(2)
    if pattern == '' then
        return
    end

    vim.b.MultiCursorPattern = '\\<' .. pattern .. '\\>'

    utils.create_extmark({
        row = cursor[1] - 1,
        end_row = cursor[1] - 1,
        col = left[2],
        end_col = right[3] + cursor[2],
    }, utils.namespace.Main)

    return true
end

--- Finds and marks all matches of a pattern in content
---@param content string[]
---@param pattern string
---@param start_row integer row offset in case of searching in a visual range
---@param start_col integer column offset in case of searching in a visual range
S.find_all_matches = function(content, pattern, start_row, start_col)
    ---@type Selection[]
    local all = {}
    local match = {}
    -- we have to add start_col as offset to first line
    repeat
        match = vim.fn.matchstrpos(content[1], pattern, match[3] or 0)
        if match[2] ~= -1 and match[3] ~= -1 then
            all[#all + 1] = {
                col = match[2] + start_col,
                end_col = match[3] + start_col,
                row = start_row,
                end_row = start_row,
            }
        end
    until match and match[2] == -1 and match[3] == -1

    match = {}
    for i = 2, #content, 1 do
        repeat
            match = vim.fn.matchstrpos(content[i], pattern, match[3] or 0)
            if match[2] ~= -1 and match[3] ~= -1 then
                all[#all + 1] = {
                    col = match[2],
                    end_col = match[3],
                    row = start_row + i - 1,
                    end_row = start_row + i - 1,
                }
            end
        until match and match[2] == -1 and match[3] == -1
    end

    if #all > 0 then
        -- make last match the main one
        utils.create_extmark(all[#all], utils.namespace.Main)
        utils.move_cursor { all[#all].end_row + 1, all[#all].end_col }
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
---@return Selection? found
S.find_next_match = function(ctx)
    if ctx.text == '' then
        return
    end

    -- \\V means very nomagic see :h \\V
    local match = vim.fn.matchstrpos(ctx.text, '\\V' .. ctx.pattern, ctx.offset)
    -- -1 range means not found
    if match[2] == -1 and match[3] == -1 then
        return
    end

    --- @type Selection
    return {
        col = match[2],
        end_col = match[3],
        row = ctx.row - 1,
        end_row = ctx.row - 1,
    }
end

--- Finds next match and marks it
---@param skip boolean
---@return Selection? next next Match
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
        return S.multiline_string(ctx.pattern, utils.position.after)
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
---@return Selection? found
S.find_prev_match = function(ctx)
    if ctx.text == '' then
        return
    end

    if ctx.till ~= -1 then
        ctx.text = ctx.text:sub(0, ctx.till)
    end

    ---@type any[]
    local match = {}
    local found = nil ---@type Selection?

    repeat
        -- \\V means very nomagic see :h \\V
        match =
            vim.fn.matchstrpos(ctx.text, '\\V' .. ctx.pattern, match[3] or 0)
        if match[2] ~= -1 and match[3] ~= -1 then
            found = {
                col = match[2],
                end_col = match[3],
                row = ctx.row - 1,
                end_row = ctx.row - 1,
            }
        end
    until match and match[2] == -1 and match[3] == -1

    return found
end

--- Finds last match before cursor
---@param skip boolean
---@return Selection? last match
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

--- Returns a selection for the char under cursor
---@return Selection
local get_cursor_char = function()
    local cursor = api.nvim_win_get_cursor(0)

    ---@type Selection
    local match = {
        col = cursor[2],
        end_col = cursor[2] + 1,
        row = cursor[1] - 1,
        end_row = cursor[1] - 1,
    }

    if match.col == 0 then
        match.end_col = 0
    end

    return match
end

--- Selects the char under the cursor as main selection
S.new_under_cursor = function()
    local match = get_cursor_char()
    vim.b.MultiCursorPattern = ''
    utils.create_extmark(match, utils.namespace.Main)
end

local get_new_position = function(motion)
    local row, col
    api.nvim_win_call(0, function()
        vim.cmd('normal! ' .. motion)
        row, col = unpack(api.nvim_win_get_cursor(0))
    end)

    -- TODO show an inline mark for zero width marks
    -- for empty lines we have to create the mark at zero
    -- and it's nt visible
    local line = api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    local end_ = col + 1
    if vim.fn.strdisplaywidth(line) == 0 then
        col = 0
        end_ = 0
    end

    return {
        row = row - 1,
        end_row = row - 1,
        col = col,
        end_col = end_,
    }
end

--- Creates a selection on the char below the cursor
---@param skip boolean skips the current selection
S.create_down = function(skip)
    local mark = get_new_position 'j'
    utils.swap_main_to(mark, skip)
end

--- Creates a selection on the char above the cursor
---@param skip boolean skips the current selection
S.create_up = function(skip)
    local mark = get_new_position 'k'
    utils.swap_main_to(mark, skip)
end

--- Creates a selection on the char above the cursor
S.create_under = function()
    local match = get_cursor_char()
    utils.swap_main_to(match, false)
end

--- Searches for multi line pattern in buffer
---@param pattern string
---@param pos ActionPosition
---@return Selection?
S.multiline_string = function(pattern, pos)
    local s, e

    -- escape regex patterns means very nomagic see :help \V
    pattern = '\\V' .. pattern

    -- 'b'	search Backward instead of forward
    -- 'c'	accept a match at the Cursor position
    -- 'e'	move to the End of the match
    -- 'n'	do Not move the cursor
    -- 'w'	Wrap around the end of the file
    -- 'z'	start searching at the cursor column instead of Zero
    local s_flags = 'wz'
    local e_flags = 'wze'

    if pos == utils.position.after then
    elseif pos == utils.position.before then
        s_flags = s_flags .. 'bn'
        e_flags = e_flags .. 'b'
    else
        s_flags = s_flags .. 'c'
        e_flags = e_flags .. 'c'
    end

    if pos == utils.position.before then
        e = vim.fn.searchpos(pattern, e_flags)
        s = vim.fn.searchpos(pattern, s_flags)
    else
        s = vim.fn.searchpos(pattern, s_flags)
        e = vim.fn.searchpos(pattern, e_flags)
    end

    if s[1] == 0 and s[1] == 0 then
        return
    end

    -- 3 is the length of \\v that's added at the start
    local end_col = s[2] + #pattern - 3
    if s[1] ~= e[1] then
        local last = find_last_index('\\n', pattern)
        -- 2 is the length of \n that's added at the start
        end_col = #pattern:sub(last) - 2
    end

    return {
        row = s[1] - 1,
        col = s[2] - 1,
        end_row = e[1] - 1,
        end_col = end_col,
    }
end

--- Searches for a pattern across buffer and creates
--- a selection for every match
---@param whole_buffer boolean
---@return boolean
S.find_pattern = function(whole_buffer)
    local content

    if whole_buffer then
        content = api.nvim_buf_get_lines(0, 0, -1, true)
    else
        content = utils.get_last_visual_range()
    end

    if #content == 0 then
        vim.notify('buffer or visual selection is empty', vim.log.levels.WARN)
        return false
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
            return false
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
    if utils.get_main_selection().id then
        return true
    end

    return false
end

--- Finds the last visualy selected text
--- @return boolean
S.find_selected = function()
    -- Exit out of visual mode
    api.nvim_feedkeys(
        api.nvim_replace_termcodes('<Esc>', false, true, true),
        'nx',
        false
    )

    local lines = utils.get_last_visual_range()

    if #lines == 0 then
        return false
    end

    -- when this command gets executed from a mapping it finds the next
    -- match so we go to start of selection to find the selected text first
    local start = api.nvim_buf_get_mark(0, '<')
    utils.move_cursor { start[1], start[2] }

    -- joins the selected case with newlines
    -- and searches for it
    local pattern = table.concat(lines, '\\n')
    local match = S.multiline_string(pattern, utils.position.on)
    if not match then
        return false
    end

    if #lines > 1 then
        vim.b.MultiCursorPattern = pattern
        vim.b.MultiCursorMultiline = true
    else
        vim.b.MultiCursorPattern = lines[1]
    end

    utils.create_extmark(match, utils.namespace.Main)
    utils.move_cursor { match.end_row + 1, match.end_col - 1 }

    return true
end

return S
