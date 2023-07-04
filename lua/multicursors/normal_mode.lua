local api = vim.api

---@type Utils
local utils = require 'multicursors.utils'

---@type Search
local search = require 'multicursors.search'

---@class InsertMode
local insert_mode = require 'multicursors.insert_mode'

local ESC = api.nvim_replace_termcodes('<Esc>', true, false, true)
local C_R = api.nvim_replace_termcodes('<C-r>', true, false, true)
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
M.find_next = function(skip)
    if vim.b.MultiCursorPattern == '' then
        return
    end
    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1] - 1
    local column = cursor[2] + #vim.b.MultiCursorPattern

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
M.find_prev = function(skip)
    if vim.b.MultiCursorPattern == '' then
        return
    end
    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1] - 1
    local column = cursor[2] - #vim.b.MultiCursorPattern

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

--- Runs a macro on the beginning of every selection
---@param config Config
M.run_macro = function(config)
    api.nvim_echo({}, false, {})
    api.nvim_echo({ { 'enter a macro register: ' } }, false, {})
    local register = utils.get_char()
    if not register or register == ESC then
        M.listen(config)
        return
    end

    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd('normal @' .. register)
    end, true, true)

    utils.exit()
end

--- Executes a normal command at every selection
---@param config Config
M.normal_command = function(config)
    vim.ui.input(
        { prompt = 'Enter normal command: ', completion = 'command' },
        function(input)
            if not input then
                M.listen(config)
                return
            end
            utils.call_on_selections(function(mark)
                api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
                vim.cmd('normal ' .. input)
            end, true, true)
        end
    )

    utils.exit()
end

--- Puts the text inside unnamed register before or after selections
---@param pos ActionPosition
M.paste = function(pos)
    utils.call_on_selections(function(mark)
        local position = { mark[1] + 1, mark[2] }
        if pos == utils.position.after then
            position = { mark[3].end_row + 1, mark[3].end_col }
        end

        api.nvim_win_set_cursor(0, position)
        vim.cmd 'normal P'
        vim.cmd 'redraw!'
    end, true, true)
end

--- Repeats last edit on every selection
---@param config Config
M.dot_repeat = function(config)
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd 'normal .'
    end, true, true)
    vim.cmd 'redraw!'
    M.listen(config)
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
---@param config Config
M.delete = function(config)
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
    M.listen(config)
end

--- Yanks the text inside selections to unnamed register
---@param config Config
M.yank = function(config)
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
    M.listen(config)
end

--- Searches for a pattern across buffer and creates
--- a selection for every match
---@param config Config
---@param whole_buffer boolean
M.pattern = function(config, whole_buffer)
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

    M.listen(config)
end

--- Selects the word under the cursor and starts listening for the actions
---@param config Config
M.start = function(config)
    M.find_cursor_word()
    M.listen(config)
end

--- Selects the char under the cursor and starts listening for the actions
---@param config Config
M.new_selection = function(config)
    M.new_under_cursor()
    M.listen(config)
end

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
---@param skip boolean
M.create_up = function(skip)
    search.create_up(skip)
end

--- Creates a selection on the line below the cursor
---@param skip boolean
M.create_down = function(skip)
    search.create_down(skip)
end

--- Listens for user actions
---@param config Config
M.listen = function(config)
    api.nvim_echo({}, false, {})
    api.nvim_echo({ { 'press a key for action : ' } }, false, {})
    while true do
        local key = utils.get_char()
        if not key then
            utils.exit()
            return
        end

        if key == ESC then
            utils.exit()
            return
        elseif key == 'j' then
            M.create_down(false)
        elseif key == '[' then
            M.goto_prev()
        elseif key == ']' then
            M.goto_next()
        elseif key == 'k' then
            M.create_up(false)
        elseif key == 'J' then
            M.create_down(true)
        elseif key == 'K' then
            M.create_up(true)
        elseif key == 'n' then
            M.find_next(false)
        elseif key == 'N' then
            M.find_prev(false)
        elseif key == 'q' then
            M.find_next(true)
        elseif key == 'Q' then
            M.find_prev(true)
        elseif key == 'p' then
            M.paste(utils.position.after)
        elseif key == 'P' then
            M.paste(utils.position.before)
        elseif key == 'y' then
            M.yank(config)
            return
        elseif key == 'd' then
            M.delete(config)
            return
        elseif key == 'u' then
            vim.cmd.undo()
        elseif key == '.' then
            M.dot_repeat(config)
            return
        elseif key == C_R then
            vim.cmd.redo()
        elseif key == 'i' then
            insert_mode.insert(config)
            return
        elseif key == 'a' then
            insert_mode.append(config)
            return
        elseif key == '@' then
            M.run_macro(config)
            return
        elseif key == ':' then
            M.normal_command(config)
            return
        elseif key == 'c' then
            M.change(config)
            return
        end
    end
end

return M
