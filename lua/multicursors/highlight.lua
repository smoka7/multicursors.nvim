---@class Highlight
local M = {}

function M.set_highlights()
    vim.api.nvim_set_hl(
        0,
        'MultiCursor',
        { fg = '#DBEC6B', bg = '#161714', default = true }
    )
    vim.api.nvim_set_hl(
        0,
        'MultiCursorMain',
        { fg = '#d6f31f', bg = '#161714', bold = true, default = true }
    )
end

return M
