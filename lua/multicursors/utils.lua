local api = vim.api

local ns_id = api.nvim_create_namespace 'multicursors'
local main_ns_id = api.nvim_create_namespace 'multicursorsmaincursor'

---@class Utils
local M = {}

--- Use action before or after cursor
---@enum ActionPosition
M.position = {
    before = 'before',
    after = 'after',
    on = 'on',
}

--- @enum Namespace
M.namespace = {
    Main = 'MultiCursorMain',
    Multi = 'MultiCursor',
}

--- Checks that start is before end otherwise swaps theme.
---@param match Match
---@return Match
local function check_match_bounds(match)
    if
        match.s_row > match.e_row
        or (match.s_row == match.e_row and match.s_col > match.e_col)
    then
        return {
            s_row = match.e_row,
            s_col = match.e_col,
            e_row = match.s_row,
            e_col = match.s_col,
        }
    end

    return match
end

--- creates a extmark for the the match
--- doesn't create a duplicate mark
---@param match Match
---@param namespace Namespace
---@return integer id of created mark
M.create_extmark = function(match, namespace)
    local ns = ns_id
    if namespace == M.namespace.Main then
        ns = main_ns_id
    end

    local marks = api.nvim_buf_get_extmarks(
        0,
        ns,
        { match.s_row, match.s_col },
        { match.e_row, match.e_col },
        {}
    )

    if #marks > 0 then
        M.debug('found ' .. #marks .. ' duplicate marks:')
        return marks[1][1]
    end

    match = check_match_bounds(match)

    local s = api.nvim_buf_set_extmark(0, ns, match.s_row, match.s_col, {
        end_row = match.e_row,
        end_col = match.e_col,
        hl_group = namespace,
    })
    return s
end

--- Deletes the extmark in current buffer in range of match
---@param match Match
---@param namespace Namespace
M.delete_extmark = function(match, namespace)
    local ns = ns_id
    if namespace == M.namespace.Main then
        ns = main_ns_id
    end

    local marks = api.nvim_buf_get_extmarks(
        0,
        ns,
        { match.s_row, match.s_col },
        { match.s_row, match.e_col },
        {}
    )
    if #marks > 0 then
        api.nvim_buf_del_extmark(0, ns, marks[1][1])
    end
end

--- Clears the namespace in current buffer
---@param namespace  Namespace
M.clear_namespace = function(namespace)
    local ns = ns_id
    if namespace == M.namespace.Main then
        ns = main_ns_id
    end
    api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

--- Clears all selction in the current buffer
M.clear_selections = function()
    M.clear_namespace(M.namespace.Main)
    M.clear_namespace(M.namespace.Multi)
end

---@param any any
M.debug = function(any)
    if vim.g.MultiCursorDebug then
        vim.notify(vim.inspect(any), vim.log.levels.DEBUG)
    end
end

--- Returns the text inside last visual selected range
---@return string[]
M.get_last_visual_range = function()
    local start = vim.fn.getpos "'<"
    local end_ = vim.fn.getpos "'>"
    local s_col = start[3] - 1
    local e_col = end_[3]

    local lines = api.nvim_buf_get_lines(0, start[2] - 1, end_[2], false)

    if #lines == 0 then
        return lines
    elseif #lines == 1 then
        lines[1] = vim.fn.strcharpart(lines[1], s_col, e_col - s_col)
    else
        lines[1] = vim.fn.strcharpart(lines[1], s_col, vim.v.maxcol)
        lines[#lines] = vim.fn.strcharpart(lines[#lines], 0, e_col)
    end

    return lines
end

--- Returns the main selection extmark
---@return Selection
M.get_main_selection = function()
    local main =
        api.nvim_buf_get_extmarks(0, main_ns_id, 0, -1, { details = true })[1]
    return {
        id = main[1],
        row = main[2],
        col = main[3],
        end_row = main[4].end_row,
        end_col = main[4].end_col,
    }
end

--- Returns a list of selections extmarks
---@return Selection[]
M.get_all_selections = function()
    local extmarks =
        api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = true })
    ---@type Selection[]
    local selections = {}
    for _, mark in pairs(extmarks) do
        selections[#selections + 1] = {
            id = mark[1],
            row = mark[2],
            col = mark[3],
            end_row = mark[4].end_row,
            end_col = mark[4].end_col,
        }
    end
    return selections
end

--- Creates a extmark for current match and
--- updates the main selection
---@param match Match match to mark
---@param skip boolean wheter or not skip current match
M.mark_found_match = function(match, skip)
    -- first clear the main selection
    -- then create a selection in place of main one
    local main = M.get_main_selection()
    M.clear_namespace(M.namespace.Main)

    if not skip then
        M.create_extmark({
            s_row = main.row,
            s_col = main.col,
            e_row = main.end_row,
            e_col = main.end_col,
        }, M.namespace.Multi)
    end
    --create the main selection
    M.create_extmark(match, M.namespace.Main)
    --deletes the selection when there was a selection there
    M.delete_extmark(match, M.namespace.Multi)
end

--- Swaps the next selection with main selection
---@param a integer[]
---@param b integer[]
---@param skip boolean
---@return boolean
local goto_first_selection = function(a, b, skip)
    local selections = api.nvim_buf_get_extmarks(
        0,
        ns_id,
        { a[1], a[2] },
        { b[1], b[2] },
        { details = true }
    )

    if #selections > 0 then
        M.mark_found_match({
            s_row = selections[1][2],
            s_col = selections[1][3],
            e_row = selections[1][4].end_row,
            e_col = selections[1][4].end_col,
        }, skip)

        M.move_cursor { selections[1][2] + 1, selections[1][3] }
        return true
    end

    return false
end

--- Swaps the next selection with main selection
--- wraps around the buffer
---@param skip boolean
M.goto_next_selection = function(skip)
    local main = M.get_main_selection()
    if
        goto_first_selection({ main.end_row, main.end_col }, { -1, -1 }, skip)
    then
        return
    end
    if goto_first_selection({ 0, 0 }, { main.end_row, main.end_col }, skip) then
        return
    end
end

--- Swaps the previous selection with main selection
--- wraps around the buffer
---@param skip boolean
M.goto_prev_selection = function(skip)
    local main = M.get_main_selection()
    if goto_first_selection({ main.end_row, main.end_col }, { 0, 0 }, skip) then
        return
    end
    if
        goto_first_selection({ -1, -1 }, { main.end_row, main.end_col }, skip)
    then
        return
    end
end

--- gets a single char from user
--- when intrupted returns nil
---@return string?
M.get_char = function()
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
        return nil
    end

    return key
end

--- Calls a callback on all selections
---@param callback fun(selection:Selection) function to call
M.call_on_selections = function(callback)
    local marks = M.get_all_selections()
    -- Get each mark again cause editing buffer might moves the other marks
    for _, selection in pairs(marks) do
        local mark = api.nvim_buf_get_extmark_by_id(
            0,
            ns_id,
            selection.id,
            { details = true }
        )

        callback {
            id = selection.id,
            row = mark[1],
            col = mark[2],
            end_row = mark[3].end_row,
            end_col = mark[3].end_col,
        }
    end

    local main = M.get_main_selection()
    callback(main)
end

--- updates each selection to a single char
---@param before ActionPosition
M.update_selections = function(before)
    local marks = M.get_all_selections()
    local main = M.get_main_selection()
    M.clear_selections()

    local col = main.end_col
    local row = main.end_row
    if before == M.position.before then
        col = main.col
        row = main.row
    end
    M.move_cursor { row + 1, col }

    M.create_extmark({
        s_row = row,
        e_row = row,
        s_col = col - 1,
        e_col = col,
    }, M.namespace.Main)

    for _, mark in pairs(marks) do
        col = mark.end_col
        row = mark.end_row
        if before == M.position.before then
            col = mark.col
            row = mark.row
        end

        M.create_extmark({
            s_row = row,
            e_row = row,
            s_col = col - 1,
            e_col = col,
        }, M.namespace.Multi)
    end
end

---
---@param length integer
M.move_selections_horizontal = function(length)
    local marks = M.get_all_selections()
    local main = M.get_main_selection()
    M.clear_selections()

    ---@param mark Selection
    ---@return integer,integer
    local get_position = function(mark)
        local col = mark.end_col + length - 1
        local row = mark.end_row

        local line =
            string.len(api.nvim_buf_get_lines(0, row, row + 1, true)[1])
        if col < 0 then
            col = -1
        elseif col >= line then
            col = line - 1
        end
        return row, col
    end

    local row, col = get_position(main)
    M.create_extmark(
        { s_col = col, e_col = col + 1, s_row = row, e_row = row },
        M.namespace.Main
    )
    M.move_cursor { row + 1, col + 1 }

    for _, mark in pairs(marks) do
        row, col = get_position(mark)

        M.create_extmark(
            { s_col = col, e_col = col + 1, s_row = row, e_row = row },
            M.namespace.Multi
        )
    end
end

---
---@param length integer
M.move_selections_vertical = function(length)
    local marks = M.get_all_selections()
    local main = M.get_main_selection()
    M.clear_selections()

    ---@param mark Selection
    ---@return integer,integer
    local get_position = function(mark)
        local col = mark.col
        local row = mark.row + length
        local buf_length = api.nvim_buf_line_count(0)

        if row < 1 then
            row = 0
        elseif row >= buf_length then
            row = buf_length - 1
        end

        local line_length =
            string.len(api.nvim_buf_get_lines(0, row, row + 1, true)[1])

        if col < 0 then
            col = -1
        elseif col >= line_length then
            col = line_length - 1
        end
        return row, col
    end

    local row, col = get_position(main)
    M.create_extmark(
        { s_col = col, e_col = col + 1, s_row = row, e_row = row },
        M.namespace.Main
    )
    M.move_cursor { row + 1, col + 1 }

    for _, mark in pairs(marks) do
        row, col = get_position(mark)
        M.create_extmark(
            { s_col = col, e_col = col + 1, s_row = row, e_row = row },
            M.namespace.Multi
        )
    end
end

---
---@param text string
M.insert_text = function(text)
    local marks = M.get_all_selections()
    for _, mark in pairs(marks) do
        local selection = api.nvim_buf_get_extmark_by_id(
            0,
            ns_id,
            mark.id,
            { details = true }
        )
        local col = selection[3].end_col
        local row = selection[3].end_row
        api.nvim_buf_set_text(0, row, col, row, col, { text })
    end

    M.move_selections_horizontal(#text)
end

--- Aligns selections by adding space
---@param line_start boolean add spaces before selection or at the start of line
M.align_text = function(line_start)
    local max_col = -1
    M.call_on_selections(function(selection)
        if selection.col > max_col then
            max_col = selection.col
        end
    end)
    local row, col, space_count
    M.call_on_selections(function(selection)
        col = selection.col
        row = selection.row
        space_count = max_col - col
        if line_start then
            col = 0
        end

        if space_count > 0 then
            api.nvim_buf_set_text(
                0,
                row,
                col,
                row,
                col,
                { string.rep(' ', space_count) }
            )
        end
    end)
end

--- Moves the cursor to pos and marks current cursor position in jumplist
--- htpps://github.com/neovim/neovim/issues/20793
---@param pos any[]
---@param current boolean?
M.move_cursor = function(pos, current)
    if current then
        local cur = api.nvim_win_get_cursor(0)
        api.nvim_buf_set_mark(0, "'", cur[1], cur[2], {})
    end

    if pos[2] < 1 then
        pos[2] = 0
    end

    api.nvim_win_set_cursor(0, { pos[1], pos[2] })
end

M.exit = function()
    M.clear_selections()
    vim.b.MultiCursorMultiline = nil
    vim.b.MultiCursorPattern = nil
    vim.b.MultiCursorSubLayer = nil
end

return M
