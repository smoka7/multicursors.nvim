local api = vim.api
local config = require 'multicursors.config'

local ns_id = api.nvim_create_namespace 'multicursors'

local M = {}

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

return M
