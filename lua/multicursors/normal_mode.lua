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
    if vim.b.MultiCursorPattern == '' then
        return
    end
    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1] - 1
    local column = cursor[2] + 1

    -- search the same line as cursor with cursor col as offset cursor
    local line = api.nvim_buf_get_lines(0, row_idx, row_idx + 1, true)[1]
    local match = search.find_next_match(line, row_idx, column, skip)
    if match then
        return match
    end

    -- search from cursor to end of buffer for pattern
    for idx = row_idx + 1, line_count - 1, 1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = search.find_next_match(line, idx, 0, skip)
        if match then
            return match
        end
    end

    -- when we didn't find the pattern we start searching again
    -- from start of the buffer
    for idx = 0, row_idx, 1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = search.find_next_match(line, idx, 0, skip)
        if match then
            return match
        end
    end
end

M.find_next = function()
    find_next(false)
end

M.skip_find_next = function()
    find_next(true)
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
    if vim.b.MultiCursorPattern == '' then
        return
    end
    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1] - 1
    local column = cursor[2] - 1

    -- search the same line untill the cursor
    local line = api.nvim_buf_get_lines(0, row_idx, row_idx + 1, true)[1]
    local match = search.find_prev_match(line, row_idx, column, skip)
    if match then
        return match
    end

    -- search from cursor to beginning of buffer for pattern
    -- fo
    for idx = row_idx - 1, 0, -1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = search.find_prev_match(line, idx, -1, skip)
        if match then
            return match
        end
    end

    -- when we didn't find the pattern we start searching again
    -- from start of the buffer
    for idx = line_count - 1, row_idx, -1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = search.find_prev_match(line, idx, -1, skip)
        if match then
            return match
        end
    end
end

M.find_prev = function()
    find_prev(false)
end

M.skip_find_prev = function()
    find_prev(true)
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
                vim.cmd('normal! ' .. input)
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
        vim.cmd 'redraw!'
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
    vim.cmd 'redraw!'
end

--- Clears the selections Except the main one
M.clear_others = function()
    utils.clear_namespace(utils.namespace.Multi)
    vim.cmd 'redraw!'
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
    vim.cmd 'redraw!'
end

M.delete_line = function()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd [[ normal! "_dd ]]
    end, true, true)
    vim.cmd 'redraw!'
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

--- Searches for a pattern across buffer and creates
--- a selection for every match
---@param whole_buffer boolean
M.pattern = function(whole_buffer)
    local range = utils.get_visual_range()
    local content = utils.get_buffer_content(whole_buffer, range)

    if not content or #content == 0 then
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

        if pattern ~= '' then
            if range and not whole_buffer then
                search.find_all_matches(
                    content,
                    pattern,
                    range.start_row,
                    range.start_col
                )
            else
                search.find_all_matches(content, pattern, 0, 0)
            end
        end
    end
end

--- Selects the word under the cursor and starts listening for the actions
M.start = function()
    M.find_cursor_word()
end

--- Selects the char under the cursor and starts listening for the actions

--- Selects the char under the cursor as main selection
M.new_under_cursor = function()
    local cursor = api.nvim_win_get_cursor(0)

    ---@type Match
    local match = {
        row = cursor[1] - 1,
        start = cursor[2],
        finish = cursor[2] + 1,
    }

    if match.start == 0 then
        match.finish = 0
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
