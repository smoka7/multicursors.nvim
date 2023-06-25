local highlight = require 'multicursors.highlight'
local normal_mode = require 'multicursors.normal_mode'

local M = {}

M.setup = function()
    highlight.set_highlights()
end

return M
