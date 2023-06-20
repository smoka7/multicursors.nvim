local utils = require 'multicursors.utils'
local api = vim.api
local M = {}

M._inserted_text = ''

--- @type number
M._au_group = api.nvim_create_augroup('multicursors', { clear = true })

--- listens for every char press and inserts the text before leaving insert mode
--TODO create a timer and update the cursors for better ux
--TODO sholud remap all cursor movements
--TODO do not mess user mappings
--TODO esc go to multicursor normal
M.start = function()
    api.nvim_create_autocmd({ 'InsertLeave' }, {
        group = M._au_group,
        callback = function()
            if M._inserted_text == '' then
                return
            end
            utils.insert_text(M._inserted_text, true)
            M._inserted_text = ''
            M.exit()
        end,
    })

    api.nvim_create_autocmd({ 'InsertCharPre' }, {
        group = M._au_group,
        callback = function()
            M._inserted_text = M._inserted_text .. vim.v.char
        end,
    })
end
M.exit = function()
    api.nvim_clear_autocmds { group = M._au_group }
end

return M
