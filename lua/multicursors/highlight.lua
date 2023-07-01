local M = {}

function M.set_highlights()
    vim.api.nvim_set_hl(0, 'MultiCursor', { fg = '#B31312', bg = '#FAF0E4' })
    vim.api.nvim_set_hl(0, 'MultiCursorMain', { fg = '#d6f31f', bg = '#f1Ffd4' })
end

return M
