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
    for _ = 1, vim.v.count1 do
        local match = search.find_next(false)
        if match then
            utils.swap_main_to(match, false)
            utils.move_cursor { match.end_row + 1, match.end_col - 1 }
        end
    end
end

M.skip_find_next = function()
    for _ = 1, vim.v.count1 do
        local match = search.find_next(true)
        if match then
            utils.swap_main_to(match, true)
            utils.move_cursor { match.end_row + 1, match.end_col - 1 }
        end
    end
end

--- Swaps the first selection in the range with main selection
---@param a integer[] start of range
---@param b integer[] end of range
---@param skip boolean skip current
---@return boolean
local goto_first_selection = function(a, b, skip)
    local selections = api.nvim_buf_get_extmarks(
        0,
        api.nvim_create_namespace 'multicursors',
        { a[1], a[2] },
        { b[1], b[2] },
        { details = true }
    )

    if #selections < 1 then
        return false
    end

    utils.swap_main_to({
        row = selections[1][2],
        col = selections[1][3],
        end_row = selections[1][4].end_row,
        end_col = selections[1][4].end_col,
    }, skip)

    utils.move_cursor { selections[1][2] + 1, selections[1][3] }
    return true
end

--- Swaps the next selection with main selection
--- wraps around the buffer
---@param skip boolean
local goto_next_selection = function(skip)
    local main = utils.get_main_selection()
    if
        goto_first_selection({ main.end_row, main.end_col }, { -1, -1 }, skip)
    then
        return
    end
    goto_first_selection({ 0, 0 }, { main.end_row, main.end_col }, skip)
end

--- Swaps the previous selection with main selection
--- wraps around the buffer
---@param skip boolean
local goto_prev_selection = function(skip)
    local main = utils.get_main_selection()
    if goto_first_selection({ main.end_row, main.end_col }, { 0, 0 }, skip) then
        return
    end
    goto_first_selection({ -1, -1 }, { main.end_row, main.end_col }, skip)
end

--- Deletes current selection and
--- Moves the main selection to next selection
M.skip_goto_next = function()
    for _ = 1, vim.v.count1 do
        goto_next_selection(true)
    end
end

--- Deletes current selection and
--- Moves the main selection to previous selection
M.skip_goto_prev = function()
    for _ = 1, vim.v.count1 do
        goto_prev_selection(true)
    end
end

--- Moves the main selection to next selection
M.goto_next = function()
    for _ = 1, vim.v.count1 do
        goto_next_selection(false)
    end
end

--- Moves the main selection to previous selection
M.goto_prev = function()
    for _ = 1, vim.v.count1 do
        goto_prev_selection(false)
    end
end

M.find_prev = function()
    for _ = 1, vim.v.count1 do
        local match = search.find_prev(false)
        if match then
            utils.swap_main_to(match, false)
            utils.move_cursor { match.row + 1, match.col }
        end
    end
end

M.skip_find_prev = function()
    for _ = 1, vim.v.count1 do
        local match = search.find_prev(true)
        if match then
            utils.swap_main_to(match, true)
            utils.move_cursor { match.row + 1, match.col }
        end
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

-- Replaces each selections text with
-- the corespondent line from the unnamed register
M.replace = function()
    local register = vim.fn.getreg ''
    local selection_count = #utils.get_all_selections() + 1

    if not register then
        return
    end

    local content ---@type string[]
    -- split register contents by lines
    if type(register) == 'string' then
        content = vim.fn.split(register, '\n') ---@type string[]
    else
        content = register
    end

    if #content ~= selection_count then
        utils.update_selections_with(function(selection)
            api.nvim_buf_set_text(
                0,
                selection.row,
                selection.col,
                selection.end_row,
                selection.end_col,
                content
            )
        end)
        return
    end

    local index = 1
    utils.update_selections_with(function(selection)
        api.nvim_buf_set_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            { content[index] }
        )
        index = index + 1
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

--- Aligns selections by adding space
---@param line_start boolean add spaces before selection or at the start of line
local align_text = function(line_start)
    local max_col = -1
    utils.call_on_selections(function(selection)
        if selection.col > max_col then
            max_col = selection.col
        end
    end)

    local col_pos, length
    utils.call_on_selections(function(selection)
        length = max_col - selection.col

        col_pos = selection.col
        if line_start then
            col_pos = 0
        end

        if length < 1 then
            return
        end

        api.nvim_buf_set_text(
            0,
            selection.row,
            col_pos,
            selection.row,
            col_pos,
            { string.rep(' ', length) }
        )
    end)
end

--- Aligns the selections by adding space before selection
M.align_selections_before = function()
    align_text(false)
end

--- Aligns the selections by adding space at start of line
M.align_selections_start = function()
    align_text(true)
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
    local count = vim.v.count1
    utils.call_on_selections(function(selection)
        api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
        utils.debug('normal! ' .. count .. '"_dd')
        vim.cmd('normal! ' .. count .. '"_dd')
    end)
end

--- Deletes from start of selection till the end of line
M.delete_end = function()
    local count = vim.v.count1
    utils.call_on_selections(function(selection)
        api.nvim_win_set_cursor(0, { selection.row + 1, selection.col })
        vim.cmd('normal! ' .. count .. '"_D')
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

M.upper_case = function()
    utils.update_selections_with(function(selection)
        local text = api.nvim_buf_get_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            {}
        )
        for i, line in ipairs(text) do
            text[i] = line:upper()
        end
        api.nvim_buf_set_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            text
        )
    end)
end

M.lower_case = function()
    utils.update_selections_with(function(selection)
        local text = api.nvim_buf_get_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            {}
        )
        for i, line in ipairs(text) do
            text[i] = line:lower()
        end
        api.nvim_buf_set_text(
            0,
            selection.row,
            selection.col,
            selection.end_row,
            selection.end_col,
            text
        )
    end)
end
--- Creates a selection on the line above the cursor
M.create_up = function()
    for _ = 1, vim.v.count1 do
        search.create_up(false)
    end
end

M.skip_create_up = function()
    for _ = 1, vim.v.count1 do
        search.create_up(true)
    end
end

--- Creates a selection on the line below the cursor
M.create_down = function()
    for _ = 1, vim.v.count1 do
        search.create_down(false)
    end
end

M.skip_create_down = function()
    for _ = 1, vim.v.count1 do
        search.create_down(true)
    end
end

--- Creates a selection for the char under cursor
M.create_char = function()
    search.create_under()
end

return M
