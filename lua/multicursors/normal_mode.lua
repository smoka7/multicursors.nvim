local api = vim.api

---@type Utils
local utils = require 'multicursors.utils'

---@type Search
local search = require 'multicursors.search'

---@class InsertMode
local insert_mode = require 'multicursors.insert_mode'

---@class NormalMode
local M = {}

M.find_next = function()
    local match = search.find_next(false)
    if match then
        utils.mark_found_match(match, false)
        utils.move_cursor { match.e_row + 1, match.e_col - 1 }
    end
end

M.skip_find_next = function()
    local match = search.find_next(true)
    if match then
        utils.mark_found_match(match, true)
        utils.move_cursor { match.e_row + 1, match.e_col - 1 }
    end
end

--- Deletes current selection and
--- Moves the main selection to next selction
M.skip_goto_next = function()
    utils.goto_next_selection(true)
end

--- Deletes current selection and
--- Moves the main selection to previous selction
M.skip_goto_prev = function()
    utils.goto_prev_selection(true)
end

--- Moves the main selection to next selction
M.goto_next = function()
    utils.goto_next_selection(false)
end

--- Moves the main selection to previous selction
M.goto_prev = function()
    utils.goto_prev_selection(false)
end

M.find_prev = function()
    local match = search.find_prev(false)
    if match then
        utils.mark_found_match(match, false)
        utils.move_cursor { match.s_row + 1, match.s_col }
    end
end

M.skip_find_prev = function()
    local match = search.find_prev(true)
    if match then
        utils.mark_found_match(match, true)
        utils.move_cursor { match.s_row + 1, match.s_col }
    end
end

--- Runs a macro on the beginning of every selection
M.run_macro = function()
    api.nvim_echo({}, false, {})
    api.nvim_echo({ { 'enter a macro register: ' } }, false, {})
    local register = utils.get_char()

    local ESC = api.nvim_replace_termcodes('<Esc>', true, false, true)
    if not register or register == ESC then
        return
    end

    utils.call_on_selections(function(selection)
        api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
        vim.cmd('normal! @' .. register)
    end)
end

--- Executes a normal command at every selection
M.normal_command = function()
    vim.ui.input(
        { prompt = 'Enter normal command: ', completion = 'command' },
        function(input)
            if not input then
                return
            end
            utils.call_on_selections(function(selection)
                api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
                vim.cmd('normal ' .. input)
            end)
        end
    )
end

--- Puts the text inside unnamed register before or after selections
---@param pos ActionPosition
local paste = function(pos)
    utils.call_on_selections(function(selection)
        local position = { selection.row + 1, selection.col }
        if pos == utils.position.after then
            position = { selection.end_row + 1, selection.end_col }
        end

        api.nvim_win_set_cursor(0, position)
        vim.cmd 'normal! P'
    end)
end

M.paste_after = function()
    paste(utils.position.after)
end

M.paste_before = function()
    paste(utils.position.before)
end

--- Repeats last edit on every selection
M.dot_repeat = function()
    utils.call_on_selections(function(selection)
        api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
        vim.cmd 'normal! .'
    end)
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
    utils.call_on_selections(function(selection)
        api.nvim_buf_set_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            {}
        )
    end)
    insert_mode.insert(config)
end

--- Deletes the text inside selections
M.delete = function()
    utils.call_on_selections(function(selection)
        api.nvim_buf_set_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            {}
        )
    end)
end

--- Deletes the line on selection
M.delete_line = function()
    utils.call_on_selections(function(selection)
        api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
        vim.cmd [[ normal! "_dd ]]
    end)
end

--- Deletes from start of selection till the end of line
M.delete_end = function()
    utils.call_on_selections(function(selection)
        api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
        vim.cmd [[ normal! "_D ]]
    end)
end

--- Yanks the text inside selections to unnamed register
M.yank = function()
    ---@type string[]
    local contents = {}
    utils.call_on_selections(function(selection)
        local text = api.nvim_buf_get_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            {}
        )
        contents[#contents + 1] = text[1]
    end)
    vim.fn.setreg('', contents)
end

--- Yanks the text in the selection line
M.yank_line = function()
    ---@type string[]
    local contents = {}
    utils.call_on_selections(function(selection)
        local text = api.nvim_buf_get_lines(
            0,
            selection.row,
            selection.end_row + 1,
            true
        )
        contents[#contents + 1] = text[1]
    end)
    vim.fn.setreg('', contents)
end

--- Yanks the text from start of the selection till end of line
M.yank_end = function()
    ---@type string[]
    local contents = {}
    utils.call_on_selections(function(selection)
        local text = api.nvim_buf_get_lines(
            0,
            selection.row,
            selection.end_row + 1,
            true
        )
        contents[#contents + 1] = text[1]:sub(selection.col + 1)
    end)
    vim.fn.setreg('', contents)
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
