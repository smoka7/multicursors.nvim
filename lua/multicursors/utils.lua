local api = vim.api
local config = require 'multicursors.config'

local ns_id = api.nvim_create_namespace 'multicursors'

local M = {}

--- creates a extmark for the the match
--- doesn't create a duplicate mark
---@param match Match
---@return integer id of created mark
M.create_extmark = function(match)
    local marks = api.nvim_buf_get_extmarks(
        0,
        ns_id,
        { match.row - 1, match.start },
        { match.row - 1, match.finish },
        {}
    )
    if #marks > 0 then
        debug('found ' .. #marks .. ' duplicate marks:')
        return marks[1][1]
    end

    local s = api.nvim_buf_set_extmark(0, ns_id, match.row - 1, match.start, {
        end_row = match.row - 1,
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

--- returns the list of cursors extmarks
---@param details boolean
---@return any[]  [extmark_id, row, col] tuples in "traversal order".
M.getAllCursors = function(details)
    local last = api.nvim_buf_line_count(0)
    local line = api.nvim_buf_get_lines(0, last - 1, last, true)[1]
    local extmarks = api.nvim_buf_get_extmarks(
        0,
        ns_id,
        0,
        { last, #line },
        { details = details }
    )
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

---
---@param text string
---@param skip_current boolean
M.insert_text = function(text, skip_current)
    local marks = M.getAllCursors(false)
    for _, value in pairs(marks) do
        -- get each mark again cause inserting text might moved the other marks
        local mark = api.nvim_buf_get_extmark_by_id(
            0,
            ns_id,
            value[1],
            { details = true }
        )

        local cursor = api.nvim_win_get_cursor(0)
        if
            not (
                skip_current
                -- match and cursor overlap
                and (cursor[1] >= mark[1] + 1 and cursor[1] <= mark[3].end_row + 1)
                and (
                    cursor[2] >= mark[2] - 1
                    -- TODO maybe we shouldn't handle this here?
                    and cursor[2] <= mark[3].end_col + #text
                )
            )
        then
            api.nvim_buf_set_text(
                0,
                mark[3].end_row,
                mark[3].end_col,
                mark[3].end_row,
                mark[3].end_col,
                { text }
            )
        end
    end
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
end

return M
