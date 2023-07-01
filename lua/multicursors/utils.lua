local api = vim.api
local config = require 'multicursors.config'

local ns_id = api.nvim_create_namespace 'multicursors'
local maincursor = api.nvim_create_namespace 'multicursorsmaincursor'

---@class Utils
local M = {}

---@enum ActionPosition
M.position = {
    before = true,
    after = false,
}

--- creates a extmark for the the match
--- doesn't create a duplicate mark
---@param match Match
---@param namespace integer
---@return integer id of created mark
M.create_extmark = function(match, namespace)
    local marks = api.nvim_buf_get_extmarks(
        0,
        namespace,
        { match.row, match.start },
        { match.row, match.finish },
        {}
    )
    if #marks > 0 then
        M.debug('found ' .. #marks .. ' duplicate marks:')
        return marks[1][1]
    end

    local s = api.nvim_buf_set_extmark(0, namespace, match.row, match.start, {
        end_row = match.row,
        end_col = match.finish,
        hl_group = 'MultiCursor',
    })
    vim.cmd [[ redraw! ]]
    return s
end

---@param any any
M.debug = function(any)
    if config.DEBUG_MODE then
        vim.notify(vim.inspect(any), vim.log.levels.DEBUG)
    end
end

---@param details boolean
---@return any
M.get_main_selection = function(details)
    return api.nvim_buf_get_extmarks(
        0,
        maincursor,
        0,
        -1,
        { details = details }
    )[1]
end

--- returns the list of cursors extmarks
---@param details boolean
---@return any[]  [extmark_id, row, col] tuples in "traversal order".
M.get_all_selections = function(details)
    local extmarks =
        api.nvim_buf_get_extmarks(0, ns_id, 0, -1, { details = details })
    return extmarks
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

--- calls a callback on all selections
---@param callback function function to call
---@param on_main boolean execute the callback on main selesction
---@param with_details boolean get the selection details
M.call_on_selections = function(callback, on_main, with_details)
    local marks = M.get_all_selections(with_details)
    for _, selection in pairs(marks) do
        -- get each mark again cause inserting text might moved the other marks
        local mark = api.nvim_buf_get_extmark_by_id(
            0,
            ns_id,
            selection[1],
            { details = true }
        )

        callback(mark)
    end

    if on_main then
        local main = M.get_main_selection(true)
        callback { main[2], main[3], main[4] }
    end
end

--- updates each selection to a single char
---@param before ActionPosition
M.update_selections = function(before)
    local marks = M.get_all_selections(true)
    local main = M.get_main_selection(true)
    M.exit()

    local col = main[4].end_col - 1
    if before then
        col = main[3] - 1
    else
        M.move_cursor { main[4].end_row + 1, main[4].end_col }
    end

    api.nvim_buf_set_extmark(0, maincursor, main[4].end_row, col, {
        end_row = main[4].end_row,
        end_col = col + 1,
        hl_group = 'MultiCursor',
    })

    for _, mark in pairs(marks) do
        col = mark[4].end_col - 1
        if before then
            col = mark[3] - 1
        end

        api.nvim_buf_set_extmark(0, ns_id, mark[4].end_row, col, {
            end_row = mark[4].end_row,
            end_col = col + 1,
            hl_group = 'MultiCursor',
        })
    end
end

---
---@param length integer
M.move_selections_horizontal = function(length)
    local marks = M.get_all_selections(true)
    local main = M.get_main_selection(true)
    M.exit()

    local get_position = function(mark)
        local col = mark[4].end_col + length - 1
        local row = mark[4].end_row

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
    M.create_extmark({ start = col, finish = col + 1, row = row }, maincursor)
    M.move_cursor { row + 1, col + 1 }

    for _, mark in pairs(marks) do
        row, col = get_position(mark)

        M.create_extmark({ start = col, finish = col + 1, row = row }, ns_id)
    end
end

---
---@param length integer
M.move_selections_vertical = function(length)
    local marks = M.get_all_selections(true)
    local main = M.get_main_selection(true)

    M.exit()

    local get_position = function(mark)
        local col = mark[3]
        local row = mark[2] + length
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
    M.create_extmark({ start = col, finish = col + 1, row = row }, maincursor)
    M.move_cursor { row + 1, col + 1 }

    for _, mark in pairs(marks) do
        row, col = get_position(mark)
        M.create_extmark({ start = col, finish = col + 1, row = row }, ns_id)
    end
end

---
---@param text string
M.insert_text = function(text)
    M.call_on_selections(function(selection)
        local col = selection[3].end_col
        local row = selection[3].end_row
        api.nvim_buf_set_text(0, row, col, row, col, { text })
    end, false, false)

    M.move_selections_horizontal(#text)
end

M.delete_char = function()
    M.call_on_selections(function(mark)
        local col = mark[3].end_col - 1
        if col < 0 then
            return
        end

        api.nvim_win_set_cursor(0, { mark[3].end_row + 1, col })
        vim.cmd [[normal x]]
    end, true, false)

    M.move_selections_horizontal(0)
end

--- Moves the cursor to pos and marks current cursor position in jumplist
--- htpps://github.com/neovim/neovim/issues/20793
---@param pos any[]
---@param current any[]?
M.move_cursor = function(pos, current)
    if not current then
        current = api.nvim_win_get_cursor(0)
    end

    api.nvim_buf_set_mark(0, "'", current[1], current[2], {})
    api.nvim_win_set_cursor(0, { pos[1], pos[2] })
    vim.cmd [[ redraw! ]]
end

M.exit = function()
    api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    api.nvim_buf_clear_namespace(0, maincursor, 0, -1)
end

return M
