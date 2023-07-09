---@type NormalMode
local N = require 'multicursors.normal_mode'

---@class Dictionary: { [string]: Action }
local normal_keys = {
    ['z'] = {
        method = N.align_selections_before,
        desc = 'Align selections before',
    },
    ['Z'] = {
        method = N.align_selections_start,
        desc = 'Align selections start',
    },
    [','] = { method = N.clear_others, desc = 'Clear others' },
    ['j'] = { method = N.create_down, desc = 'Create down' },
    ['k'] = { method = N.create_up, desc = 'Create up' },
    ['.'] = { method = N.dot_repeat, desc = 'Dot repeat' },
    ['n'] = { method = N.find_next, desc = 'Find next' },
    ['q'] = { method = N.skip_find_next, desc = 'Skip find next' },
    ['Q'] = { method = N.skip_find_prev, desc = 'Skip find prev' },
    ['N'] = { method = N.find_prev, desc = 'Find prev' },
    [']'] = { method = N.goto_next, desc = 'Goto next' },
    ['['] = { method = N.goto_prev, desc = 'Goto prev' },
    ['p'] = { method = N.paste_after, desc = 'Paste after' },
    ['P'] = { method = N.paste_before, desc = 'Paste before' },
    ['@'] = { method = N.run_macro, desc = 'Run macro' },
    [':'] = { method = N.normal_command, desc = 'Normal command' },
    ['J'] = { method = N.skip_create_down, desc = 'Skip create down' },
    ['K'] = { method = N.skip_create_up, desc = 'Skip create up' },
    ['y'] = { method = N.yank, desc = 'Yank' },
    ['Y'] = { method = N.yank_end, desc = 'Yank end' },
    ['yy'] = { method = N.yank_line, desc = 'Yank line' },
    ['d'] = { method = N.delete, desc = 'Delete' },
    ['dd'] = { method = N.delete_line, desc = 'Delete line' },
    ['D'] = { method = N.delete_end, desc = 'Delete end' },
}

--- TODO highlight custumization
---@class Config
local M = {
    DEBUG_MODE = false,
    create_commands = true, -- create Multicursor user commands
    updatetime = 50, -- selections get updated if this many milliseconds nothing is typed in the insert mode see :help updatetime
    normal_keys = normal_keys,
}

return M
