local api = vim.api

---@type Utils
local utils = require 'multicursors.utils'

---@type Search
local search = require 'multicursors.search'

---@class InsertMode
local insert_mode = require 'multicursors.insert_mode'

local ESC = api.nvim_replace_termcodes('<Esc>', true, false, true)
local CR = api.nvim_replace_termcodes('<cr>', true, false, true)
local BS = api.nvim_replace_termcodes('<bs>', true, false, true)

---@class NormalMode
local M = {}

--- Selects the word under the cursor as main selection
M.find_cursor_word = function()
    local match = search.find_cursor_word()
    if not match then
        return
    end

    utils.create_extmark(match, utils.namespace.Main)
end

--- Finds next match and marks it
---@param skip boolean
---@return Match? next next Match
local find_next = function(skip)
    local pattern = vim.b.MultiCursorPattern
    if not pattern or pattern == '' then
        return
    end

    if vim.b.MultiCursorMultiline then
        local match = search.multiline_string(pattern, utils.position.after)
        if match then
            utils.mark_found_match(match, skip)
            utils.move_cursor { match.e_row + 1, match.e_col + 1 }
            return match
        end
    end

    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1]
    local column = cursor[2]
    local buffer = api.nvim_buf_get_lines(0, 0, -1, true)

    -- search the same line as cursor with cursor col as offset cursor
    local match = search.find_next_match(buffer[row_idx], pattern, column)

    if match then
        match.s_row = row_idx - 1
        match.e_row = row_idx - 1
        utils.mark_found_match(match, skip)
        return match
    end
    ---

    -- search from cursor to end of buffer for pattern
    for idx = row_idx + 1, line_count, 1 do
        match = search.find_next_match(buffer[idx], pattern, 0)
        if match then
            match.s_row = idx - 1
            match.e_row = idx - 1
            utils.mark_found_match(match, skip)
            return match
        end
    end
    --

    -- At end wrap around the buffer when we can't match anything
    for idx = 1, row_idx + 1, 1 do
        match = search.find_next_match(buffer[idx], pattern, 0)
        if match then
            match.s_row = idx - 1
            match.e_row = idx - 1
            utils.mark_found_match(match, skip)
            return match
        end
    end
end

M.find_next = function()
    local match = find_next(false)
    if match then
        utils.move_cursor { match.e_row + 1, match.e_col + 1 }
    end
end

M.skip_find_next = function()
    local match = find_next(true)
    if match then
        utils.move_cursor { match.e_row + 1, match.e_col + 1 }
    end
end

--- Moves the main selection to next selction
M.goto_next = function()
    utils.goto_next_selection()
end

--- Moves the main selection to previous selction
M.goto_prev = function()
    utils.goto_prev_selection()
end

---finds previous match and marks it
---@param skip boolean
---@return Match? prev previus match
local find_prev = function(skip)
    local pattern = vim.b.MultiCursorPattern
    if not pattern or pattern == '' then
        return
    end

    if vim.b.MultiCursorMultiline then
        local match = search.multiline_string(pattern, utils.position.before)
        if match then
            utils.mark_found_match(match, skip)
            return match
        end
    end

    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1]
    local column = cursor[2]
    local buffer = api.nvim_buf_get_lines(0, 0, -1, true)

    -- search the cursor line
    local match = search.find_prev_match(buffer[row_idx], pattern, column)
    if match then
        match.s_row = row_idx - 1
        match.e_row = row_idx - 1
        utils.mark_found_match(match, skip)
        return match
    end
    --

    -- search from cursor to start of buffer
    for idx = row_idx - 1, 1, -1 do
        match = search.find_prev_match(buffer[idx], pattern, -1)
        if match then
            match.s_row = idx - 1
            match.e_row = idx - 1
            utils.mark_found_match(match, skip)
            return match
        end
    end
    --

    --At end wrap around the buffer when we can't match anything
    for idx = line_count, row_idx, -1 do
        match = search.find_prev_match(buffer[idx], pattern, -1)
        if match then
            match.s_row = idx - 1
            match.e_row = idx - 1
            utils.mark_found_match(match, skip)
            return match
        end
    end
end

M.find_prev = function()
    local match = find_prev(false)
    if match then
        utils.move_cursor { match.s_row + 1, match.s_col - 1 }
    end
end

M.skip_find_prev = function()
    local match = find_prev(true)
    if match then
        utils.move_cursor { match.s_row + 1, match.s_col - 1 }
    end
end

--- Runs a macro on the beginning of every selection
M.run_macro = function()
    api.nvim_echo({}, false, {})
    api.nvim_echo({ { 'enter a macro register: ' } }, false, {})
    local register = utils.get_char()
    if not register or register == ESC then
        return
    end

    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd('normal! @' .. register)
    end, true, true)
end

--- Executes a normal command at every selection
M.normal_command = function()
    vim.ui.input(
        { prompt = 'Enter normal command: ', completion = 'command' },
        function(input)
            if not input then
                return
            end
            utils.call_on_selections(function(mark)
                api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
                vim.cmd('normal ' .. input)
            end, true, true)
        end
    )
end

--- Puts the text inside unnamed register before or after selections
---@param pos ActionPosition
local paste = function(pos)
    utils.call_on_selections(function(mark)
        local position = { mark[1] + 1, mark[2] }
        if pos == utils.position.after then
            position = { mark[3].end_row + 1, mark[3].end_col }
        end

        api.nvim_win_set_cursor(0, position)
        vim.cmd 'normal! P'
    end, true, true)
end

M.paste_after = function()
    paste(utils.position.after)
end

M.paste_before = function()
    paste(utils.position.before)
end

--- Repeats last edit on every selection
M.dot_repeat = function()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd 'normal! .'
    end, true, true)
end

--- Clears the selections Except the main one
M.clear_others = function()
    utils.clear_namespace(utils.namespace.Multi)
end

--- Aligns the selections by adding space
---@param line_start boolean
M.align_selections = function(line_start)
    utils.align_text(line_start)
end

--- Aligns the selections by adding space before selection
M.align_selections_before = function()
    utils.align_text(false)
end

--- Aligns the selections by adding space at start of line
M.align_selections_start = function()
    utils.align_text(true)
end

--- Deletes the text inside selections and starts insert mode
---@param config Config
M.change = function(config)
    utils.call_on_selections(function(mark)
        api.nvim_buf_set_text(
            0,
            mark[1],
            mark[2],
            mark[3].end_row,
            mark[3].end_col,
            {}
        )
    end, true, true)
    insert_mode.insert(config)
end

--- Deletes the text inside selections
M.delete = function()
    utils.call_on_selections(function(mark)
        api.nvim_buf_set_text(
            0,
            mark[1],
            mark[2],
            mark[3].end_row,
            mark[3].end_col,
            {}
        )
    end, true, true)
end

--- Deletes the line on selection
M.delete_line = function()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd [[ normal! "_dd ]]
    end, true, true)
end

--- Deletes from start of selection till the end of line
M.delete_end = function()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd [[ normal! "_D ]]
    end, true, true)
end

--- Yanks the text inside selections to unnamed register
M.yank = function()
    ---@type string[]
    local contents = {}
    utils.call_on_selections(function(mark)
        local text = api.nvim_buf_get_text(
            0,
            mark[1],
            mark[2],
            mark[3].end_row,
            mark[3].end_col,
            {}
        )
        contents[#contents + 1] = text[1]
    end, true, true)
    vim.fn.setreg('', contents)
end

--- Yanks the text in the selection line
M.yank_line = function()
    ---@type string[]
    local contents = {}
    utils.call_on_selections(function(mark)
        local text =
            api.nvim_buf_get_lines(0, mark[1], mark[3].end_row + 1, true)
        contents[#contents + 1] = text[1]
    end, true, true)
    vim.fn.setreg('', contents)
end

--- Yanks the text from start of the selection till end of line
M.yank_end = function()
    ---@type string[]
    local contents = {}
    utils.call_on_selections(function(mark)
        local text =
            api.nvim_buf_get_lines(0, mark[1], mark[3].end_row + 1, true)
        contents[#contents + 1] = text[1]:sub(mark[2] + 1)
    end, true, true)
    vim.fn.setreg('', contents)
end

--- Selects the text in visual mode
M.search_selected = function()
    -- Exit out of visual mode
    -- TODO check from normal that it deosn't have side effects
    api.nvim_feedkeys(
        api.nvim_replace_termcodes('<Esc>', false, true, true),
        'nx',
        false
    )

    -- Gets the range of last selected text
    --- FIXME multibyte characters doesn't get picked correctly
    local start, end_ = utils.get_last_visual_range()
    if not start or not end_ then
        return
    end

    local lines = utils.get_buffer_content(start, end_)

    -- joins the selected case with newlines
    -- and searches for it
    -- FIXME executed from command mode returns the selected range
    -- but when from visaul mode with a mappings select next match
    -- when cursur is at end of visual
    local pattern = table.concat(lines, '\\n')
    local match = search.multiline_string(pattern, 'on')
    if not match then
        return
    end

    vim.b.MultiCursorPattern = pattern
    vim.b.MultiCursorMultiline = true

    utils.create_extmark(match, utils.namespace.Main)
    utils.move_cursor { match.e_row + 1, match.e_col + 1 }
end

--- Searches for a pattern across buffer and creates
--- a selection for every match
---@param whole_buffer boolean
M.pattern = function(whole_buffer)
    local content, start, end_

    if whole_buffer then
        content = api.nvim_buf_get_lines(0, 0, -1, true)
    else
        start, end_ = utils.get_last_visual_range()
        if not start or not end_ then
            return
        end
        content = utils.get_buffer_content(start, end_)
    end

    if #content == 0 then
        vim.notify('buffer or visual selection is empty', vim.log.levels.WARN)
        return
    end

    api.nvim_echo({}, false, {})
    api.nvim_echo({ { 'enter a pattern : ' } }, false, {})

    local pattern = ''
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
        --clear the old selection every key press
        vim.b.MultiCursorPattern = pattern
        utils.clear_namespace 'MultiCursor'
        utils.clear_namespace 'MultiCursorMain'

        api.nvim_echo({}, false, {})
        api.nvim_echo({ { 'enter a pattern : ' .. pattern } }, false, {})

        if pattern ~= '' then
            if not whole_buffer then
                search.find_all_matches(content, pattern, start.row, start.col)
            else
                search.find_all_matches(content, pattern, 0, 0)
            end
        end
    end
end

--- Selects the char under the cursor as main selection
M.new_under_cursor = function()
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

--- Creates a selection on the line top of the cursor
M.create_up = function()
    search.create_up(false)
end

M.skip_create_up = function()
    search.create_up(true)
end

--- Creates a selection on the line below the cursor
M.create_down = function()
    search.create_down(false)
end

M.skip_create_down = function()
    search.create_down(true)
end
return M
