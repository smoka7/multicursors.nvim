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
---@param sel Selection
---@return Selection
local function check_selection_bounds(sel)
    if
        sel.row > sel.end_row
        or (sel.row == sel.end_row and sel.col > sel.end_col)
    then
        return {
            id = sel.id,
            row = sel.end_row,
            col = sel.end_col,
            end_row = sel.row,
            end_col = sel.col,
        }
    end

    return sel
end

--- Creates a mark for selection in namespace
--- if selection has a id updates the mark
--- deletes old marks in range of new selection
---@param selection Selection
---@param namespace Namespace
---@return integer
M.create_extmark = function(selection, namespace)
    local ns = ns_id
    if namespace == M.namespace.Main then
        ns = main_ns_id
    end

    --TODO delete for next nvim release
    local opts = {}
    if vim.version.gt(vim.version(), { 0, 9, 9 }) then
        opts = { overlap = true }
    end

    local marks = api.nvim_buf_get_extmarks(
        0,
        ns,
        { selection.row, selection.col },
        { selection.end_row, selection.end_col },
        opts
    )
    -- Delete the old marks
    for _, mark in pairs(marks) do
        if selection.id ~= mark[1] then
            api.nvim_buf_del_extmark(0, ns, mark[1])
        end
    end

    selection = check_selection_bounds(selection)

    return api.nvim_buf_set_extmark(0, ns, selection.row, selection.col, {
        id = selection.id,
        hl_group = namespace,
        end_row = selection.end_row,
        end_col = selection.end_col,
    })
end

--- Deletes the extmark in current buffer in range of selection
---@param selection Selection
---@param namespace Namespace
M.delete_extmark = function(selection, namespace)
    local ns = ns_id
    if namespace == M.namespace.Main then
        ns = main_ns_id
    end

    local marks = api.nvim_buf_get_extmarks(
        0,
        ns,
        { selection.row, selection.col },
        { selection.end_row, selection.end_col },
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
    local start = vim.fn.getcharpos "'<"
    local end_ = vim.fn.getcharpos "'>"
    local col = start[3] - 1
    local end_col = end_[3]

    local lines = api.nvim_buf_get_lines(0, start[2] - 1, end_[2], false)

    if #lines == 0 then
        return lines
    elseif #lines == 1 then
        lines[1] = vim.fn.strcharpart(lines[1], col, end_col - col)
    else
        lines[1] = vim.fn.strcharpart(lines[1], col, vim.v.maxcol)
        lines[#lines] = vim.fn.strcharpart(lines[#lines], 0, end_col)
    end

    return lines
end

--- Returns the main selection extmark
---@return Selection
M.get_main_selection = function()
    local main =
        api.nvim_buf_get_extmarks(0, main_ns_id, 0, -1, { details = true })[1]

    if not main then
        return {}
    end

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

--- Updates the main selection to new selection
---@param new Selection
---@param skip boolean wheter or not skip current match
M.swap_main_to = function(new, skip)
    -- first clear the main selection
    -- then create a selection in place of main one
    local main = M.get_main_selection()

    -- swap the selection ids
    new.id = main.id
    main.id = nil

    if not skip then
        M.create_extmark(main, M.namespace.Multi)
    end

    M.create_extmark(new, M.namespace.Main)
    M.delete_extmark(new, M.namespace.Multi)
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

-- Calls the callback on each selection
-- Deletes and recreats each extmark
---@param callback function
M.update_selections_with = function(callback)
    local marks = M.get_all_selections()
    -- Get each mark again cause editing buffer might moves the other marks
    for _, selection in pairs(marks) do
        local mark = api.nvim_buf_get_extmark_by_id(
            0,
            ns_id,
            selection.id,
            { details = true }
        )
        local s = {
            id = selection.id,
            row = mark[1],
            col = mark[2],
            end_row = mark[3].end_row,
            end_col = mark[3].end_col,
        }

        -- Delete each mark and recreate it after running callbacks
        api.nvim_buf_del_extmark(0, ns_id, s.id)
        callback(s)
        M.create_extmark(s, 'MultiCursor')
    end

    local main = M.get_main_selection()
    api.nvim_buf_del_extmark(0, main_ns_id, main.id)
    callback(main)
    M.create_extmark(main, 'MultiCursorMain')
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
