local api = vim.api

---@class Utils
local utils = require 'multicursors.utils'

---@class InsertMode
local insert_mode = require 'multicursors.insert_mode'

local debug = utils.debug

local ESC = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
local C_R = vim.api.nvim_replace_termcodes('<C-r>', true, false, true)

---@class NormalMode
local M = {}

--- Returns the first match for pattern after a offset in a string
---@param string string
---@param row_idx integer
---@param offset integer
---@param skip boolean
---@return Match?
local find_next_match = function(string, row_idx, offset, skip)
    if not string or string == '' then
        return
    end

    if offset ~= 0 then
        string = string:sub(offset + 1, -1)
    end
    local pattern = vim.b.MultiCursorPattern

    local match = vim.fn.matchstrpos(string, '\\<' .. pattern .. '\\>')
    -- -1 range means not found
    if match[2] == -1 and match[3] == -1 then
        return
    end

    --- @class Match
    local found = {
        -- add offset to match position index
        start = match[2] + offset,
        finish = match[3] + offset,
        row = row_idx,
    }

    -- jump the cursor to last match
    local main = utils.get_main_selection(true)
    utils.clear_namespace(utils.namespace.Main)
    if not skip then
        --api.nvim_buf_del_extmark(0,utils.namespace.Main)
        utils.create_extmark(
            { row = main[2], start = main[3], finish = main[4].end_col },
            utils.namespace.Multi
        )
    end
    utils.create_extmark(found, utils.namespace.Main)
    utils.delete_extmark(found, utils.namespace.Multi)
    utils.move_cursor({ row_idx + 1, found.start }, nil)

    return found
end

--- Returns the last match before the cursor
---@param string string
---@param row_idx integer
---@param till integer
---@param skip boolean
---@return Match?
local find_prev_match = function(string, row_idx, till, skip)
    if not string or string == '' then
        return
    end
    local sub = string
    if till ~= -1 then
        sub = string:sub(0, till)
    end
    ---@type any[]?
    local match = nil
    ---@type Match?
    local found = nil
    local offset = 0
    local pattern = vim.b.MultiCursorPattern
    repeat
        match = vim.fn.matchstrpos(sub, '\\<' .. pattern .. '\\>')
        -- -1 range means not found
        if match[2] ~= -1 and match[3] ~= -1 then
            found = {
                start = match[2] + offset, -- add offset to match position index
                finish = match[3] + offset,
                row = row_idx,
            }
            offset = offset + match[3]
            sub = string:sub(offset + 1, till)
        end
    until match and match[2] == -1 and match[3] == -1

    if not found then
        return
    end

    -- jump the cursor to last match
    local main = utils.get_main_selection(true)
    utils.clear_namespace(utils.namespace.Main)
    if not skip then
        utils.create_extmark(
            { row = main[2], start = main[3], finish = main[4].end_col },
            utils.namespace.Multi
        )
    end
    utils.create_extmark(found, utils.namespace.Main)
    utils.delete_extmark(found, utils.namespace.Multi)
    utils.move_cursor({ row_idx + 1, found.start }, nil)

    return found
end
--
-- creates a mark for word under the cursor
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
        row = cursor[1] - 1,
        start = left[2],
        finish = right[3] + cursor[2],
        pattern = left[1] .. right[1]:sub(2),
    }
    utils.create_extmark(match, utils.namespace.Main)
    vim.b.MultiCursorPattern = left[1] .. right[1]:sub(2)
end

---finds next match and marks it
---@param skip boolean
---@return Match? next next Match
M.find_next = function(skip)
    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1] - 1
    local column = cursor[2] + #vim.b.MultiCursorPattern

    -- search the same line as cursor with cursor col as offset cursor
    local line = api.nvim_buf_get_lines(0, row_idx, row_idx + 1, true)[1]
    local match = find_next_match(line, row_idx, column, skip)
    if match then
        return match
    end

    -- search from cursor to end of buffer for pattern
    for idx = row_idx + 1, line_count - 1, 1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = find_next_match(line, idx, 0, skip)
        if match then
            return match
        end
    end

    -- when we didn't find the pattern we start searching again
    -- from start of the buffer
    for idx = 0, row_idx, 1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = find_next_match(line, idx, 0, skip)
        if match then
            return match
        end
    end
end

---finds previous match and marks it
---@param skip boolean
---@return Match? prev previus match
M.find_prev = function(skip)
    local line_count = api.nvim_buf_line_count(0)
    local cursor = api.nvim_win_get_cursor(0)
    local row_idx = cursor[1] - 1
    local column = cursor[2] - #vim.b.MultiCursorPattern

    -- search the same line untill the cursor
    local line = api.nvim_buf_get_lines(0, row_idx, row_idx + 1, true)[1]
    local match = find_prev_match(line, row_idx, column, skip)
    if match then
        return match
    end

    -- search from cursor to beginning of buffer for pattern
    -- fo
    for idx = row_idx - 1, 0, -1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = find_prev_match(line, idx, -1, skip)
        if match then
            return match
        end
    end

    -- when we didn't find the pattern we start searching again
    -- from start of the buffer
    for idx = line_count - 1, row_idx, -1 do
        line = api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
        match = find_prev_match(line, idx, -1, skip)
        if match then
            return match
        end
    end
end

--- runs a macro on the beginning of every selection
---@param config Config
M.run_macro = function(config)
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

--- executes a normal command at every selection
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

--- puts the text inside unnamed register before or after selections
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

M.dot_repeat = function()
    utils.call_on_selections(function(mark)
        api.nvim_win_set_cursor(0, { mark[1] + 1, mark[2] })
        vim.cmd 'normal .'
    end, true, true)
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
    M.listen(config)
end

--- yanks the text inside selections to unnamed register
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

--- Selects the word under cursor and starts listening for the actions
---@param config Config
M.start = function(config)
    M.find_cursor_word()
    debug 'listening for mod selector'
    M.listen(config)
end

---@param config Config
M.listen = function(config)
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
            M.dot_repeat()
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
