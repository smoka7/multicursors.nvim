local api = vim.api

local highlight = require 'multicursors.highlight'
local config = require 'multicursors.config'

local ns_id = api.nvim_create_namespace 'multicursors'

---@param any any
local function debug(any)
    if config.DEBUG_MODE then
        vim.notify(vim.inspect(any), vim.log.levels.DEBUG)
    end
end

local M = {}

--- Moves the cursor to pos and marks current cursor position in jumplist
--- htpps://github.com/neovim/neovim/issues/20793
---@param pos any[]
---@param current any[]?
local function move_cursor(pos, current)
    if not current then
        current = api.nvim_win_get_cursor(0)
    end

    api.nvim_buf_set_mark(0, "'", current[1], current[2], {})
    api.nvim_win_set_cursor(0, { pos[1], pos[2] })
    vim.cmd [[ redraw! ]]
end

--- creates a extmark for the the match
--- doesn't create a duplicate mark
---@param match Match
---@return integer id of created mark
local create_extmark = function(match)
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

    return api.nvim_buf_set_extmark(0, ns_id, match.row - 1, match.start, {
        end_row = match.row - 1,
        end_col = match.finish,
        hl_group = 'MultiCursor',
    })
end

-- creates a mark for word under the cursor
---@return integer?,string?
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

    local word = {
        row = cursor[1],
        start = left[2],
        finish = right[3] + cursor[2],
    }

    local mark_id = create_extmark(word)
    move_cursor { cursor[1], cursor[2] + right[3] }

    return mark_id, left[1] .. right[1]:sub(2)
end
