---@type NormalMode
local N = require 'multicursors.normal_mode'

---@type InsertMode
local I = require 'multicursors.insert_mode'

---@type ExtendMode
local E = require 'multicursors.extend_mode'

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
    ['}'] = { method = N.skip_goto_next, desc = 'Skip Goto next' },
    ['{'] = { method = N.skip_goto_prev, desc = 'Skip Goto prev' },
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

---@class Dictionary: { [string]: Action }
local extend_keys = {
    ['w'] = { method = E.w_method, opts = { desc = '' } },
    ['e'] = { method = E.e_method, opts = { desc = '' } },
    ['b'] = { method = E.b_method, opts = { desc = '' } },
    ['o'] = { method = E.o_method, opts = { desc = '' } },
    ['O'] = { method = E.o_method, opts = { desc = '' } },
    ['h'] = { method = E.h_method, opts = { desc = '' } },
    ['j'] = { method = E.j_method, opts = { desc = '' } },
    ['k'] = { method = E.k_method, opts = { desc = '' } },
    ['l'] = { method = E.l_method, opts = { desc = '' } },
    ['r'] = { method = E.node_first_child, opts = { desc = '' } },
    ['t'] = { method = E.node_parent, opts = { desc = '' } },
    ['y'] = { method = E.node_last_child, opts = { desc = '' } },
    ['^'] = { method = E.caret_method, opts = { desc = '' } },
    ['$'] = { method = E.dollar_method, opts = { desc = '' } },
    ['u'] = { method = E.undo_history, opts = { desc = '' } },
    ['c'] = { method = E.custom_method, opts = { desc = '' } },
}

---@class Dictionary: { [string]: Action }
local insert_keys = {

    ['<BS>'] = { method = I.BS_method, desc = '' },
    ['<CR>'] = { method = I.CR_method, desc = '' },
    ['<Del>'] = { method = I.Del_method, desc = '' },

    ['<C-w>'] = { method = I.C_w_method, desc = '' },
    ['<C-BS>'] = { method = I.C_w_method, desc = '' },
    ['<C-u>'] = { method = I.C_u_method, desc = '' },
    ['<C-j>'] = { method = I.CR_method, desc = '' },

    ['<Esc>'] = { method = nil, desc = '' },
    ['<C-c>'] = { method = nil, desc = '' },

    ['<End>'] = { method = I.End_method, desc = '' },
    ['<Home>'] = { method = I.Home_method, desc = '' },
    ['<Right>'] = { method = I.Right_method, desc = '' },
    ['<Left>'] = { method = I.Left_method, desc = '' },
    ['<Down>'] = { method = I.Down_method, desc = '' },
    ['<Up>'] = { method = I.UP_method, desc = '' },
}

--- TODO highlight custumization
---@class Config
local M = {
    DEBUG_MODE = false,
    create_commands = true, -- create Multicursor user commands
    updatetime = 50, -- selections get updated if this many milliseconds nothing is typed in the insert mode see :help updatetime
    nowait = true, -- see :help :map-nowait
    normal_keys = normal_keys,
    insert_keys = insert_keys,
    extend_keys = extend_keys,
    hint_config = {
        border = 'none',
        position = 'bottom',
    }, -- see :help hydra-config.hint
    generate_hints = {
        hint_column = 4, -- 1-9 or 'width'
        normal = true,
        insert = true,
        extend = true,
    }, -- true:generate hints false:don't genrate or provide your own hints
}

return M
