local M = {}

function M.set_highlights()
    vim.api.nvim_set_hl(0, 'MultiCursor', { fg = '#B31312', bg = '#FAF0E4' })
end

return M
