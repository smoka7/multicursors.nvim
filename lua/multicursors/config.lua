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
        opts = { desc = 'Align before' },
    },
    ['Z'] = {
        method = N.align_selections_start,
        opts = { desc = 'Align start' },
    },
    [','] = {
        method = N.clear_others,
        opts = { desc = 'Clear others' },
    },
    ['<C-n>'] = {
        method = N.create_char,
        opts = { desc = 'Creates a Selection under cursor' },
    },
    ['j'] = { method = N.create_down, opts = { desc = 'Create down' } },
    ['k'] = { method = N.create_up, opts = { desc = 'Create up' } },
    ['.'] = { method = N.dot_repeat, opts = { desc = 'Dot repeat' } },
    ['n'] = { method = N.find_next, opts = { desc = 'Find next' } },
    ['q'] = { method = N.skip_find_next, opts = { desc = 'Skip find next' } },
    ['Q'] = { method = N.skip_find_prev, opts = { desc = 'Skip find prev' } },
    ['N'] = { method = N.find_prev, opts = { desc = 'Find prev' } },
    ['}'] = { method = N.skip_goto_next, opts = { desc = 'Skip Goto next' } },
    ['{'] = { method = N.skip_goto_prev, opts = { desc = 'Skip Goto prev' } },
    [']'] = { method = N.goto_next, opts = { desc = 'Goto next' } },
    ['['] = { method = N.goto_prev, opts = { desc = 'Goto prev' } },
    ['p'] = { method = N.paste_after, opts = { desc = 'Paste after' } },
    ['r'] = { method = N.replace, opts = { desc = 'Replace selections text' } },
    ['P'] = { method = N.paste_before, opts = { desc = 'Paste before' } },
    ['@'] = { method = N.run_macro, opts = { desc = 'Run macro' } },
    [':'] = { method = N.normal_command, opts = { desc = 'Normal command' } },
    ['U'] = { method = N.upper_case, opts = { desc = 'Upper case' } },
    ['u'] = { method = N.lower_case, opts = { desc = 'lower case' } },
    ['J'] = {
        method = N.skip_create_down,
        opts = { desc = 'Skip create down' },
    },
    ['K'] = { method = N.skip_create_up, opts = { desc = 'Skip create up' } },
    ['y'] = { method = N.yank, opts = { desc = 'Yank', nowait = false } },
    ['Y'] = { method = N.yank_end, opts = { desc = 'Yank end' } },
    ['yy'] = { method = N.yank_line, opts = { desc = 'Yank line' } },
    ['d'] = { method = N.delete, opts = { desc = 'Delete', nowait = false } },
    ['dd'] = { method = N.delete_line, opts = { desc = 'Delete line' } },
    ['D'] = { method = N.delete_end, opts = { desc = 'Delete end' } },
}

---@class Dictionary: { [string]: Action }
local extend_keys = {
    ['w'] = { method = E.w_method, opts = { desc = 'start word forward' } },
    ['e'] = { method = E.e_method, opts = { desc = 'end word forward' } },
    ['b'] = { method = E.b_method, opts = { desc = 'start word backward' } },
    ['o'] = { method = E.o_method, opts = { desc = 'toggle anchor' } },
    ['O'] = { method = E.o_method, opts = { desc = 'toggle anchor' } },
    ['h'] = { method = E.h_method, opts = { desc = 'char left' } },
    ['j'] = { method = E.j_method, opts = { desc = 'char down' } },
    ['k'] = { method = E.k_method, opts = { desc = 'char up' } },
    ['l'] = { method = E.l_method, opts = { desc = 'char right' } },
    ['r'] = {
        method = E.node_first_child,
        opts = { desc = 'ts node first child' },
    },
    ['t'] = { method = E.node_parent, opts = { desc = 'ts node parent' } },
    ['y'] = {
        method = E.node_last_child,
        opts = { desc = 'ts node last child' },
    },
    ['^'] = { method = E.caret_method, opts = { desc = 'start of line' } },
    ['$'] = { method = E.dollar_method, opts = { desc = 'end of line' } },
    ['u'] = { method = E.undo_history, opts = { desc = 'undo last extend' } },
    ['c'] = { method = E.custom_method, opts = { desc = 'custom motion' } },
}

---@class Dictionary: { [string]: Action }
local insert_keys = {

    ['<BS>'] = { method = I.BS_method, opts = { desc = 'backspace' } },
    ['<CR>'] = { method = I.CR_method, opts = { desc = 'newline' } },
    ['<Del>'] = { method = I.Del_method, opts = { desc = 'delete char' } },

    ['<C-w>'] = {
        method = I.C_w_method,
        opts = {
            desc = 'delete word backward',
        },
    },
    ['<C-BS>'] = {
        method = I.C_w_method,
        opts = { desc = 'delete word backward' },
    },
    ['<C-u>'] = {
        method = I.C_u_method,
        opts = { desc = 'delete till start of line' },
    },
    ['<C-j>'] = { method = I.CR_method, opts = { desc = 'new line' } },

    ['<C-Right>'] = { method = I.C_Right, opts = { desc = 'word forward' } },
    ['<C-Left>'] = { method = I.C_Left, opts = { desc = 'word backward' } },

    ['<Esc>'] = { method = nil, opts = { desc = 'exit' } },
    ['<C-c>'] = { method = nil, opts = { desc = 'exit' } },

    ['<End>'] = {
        method = I.End_method,
        opts = { desc = 'move to end of line' },
    },
    ['<Home>'] = {
        method = I.Home_method,
        opts = { desc = 'move to start of line' },
    },
    ['<Right>'] = { method = I.Right_method, opts = { desc = 'move right' } },
    ['<Left>'] = { method = I.Left_method, opts = { desc = 'move left' } },
    ['<Down>'] = { method = I.Down_method, opts = { desc = 'move down' } },
    ['<Up>'] = { method = I.UP_method, opts = { desc = 'move up' } },
}

---@class Config
local M = {
    DEBUG_MODE = false,
    create_commands = true, -- create Multicursor user commands
    updatetime = 50, -- selections get updated if this many milliseconds nothing is typed in the insert mode see :help updatetime
    nowait = true, -- see :help :map-nowait
    mode_keys = {
        append = 'a',
        change = 'c',
        extend = 'e',
        insert = 'i',
    }, -- set bindings to start these modes
    normal_keys = normal_keys,
    insert_keys = insert_keys,
    extend_keys = extend_keys,
    -- see :help hydra-config.hint
    hint_config = {
        border = 'none',
        position = 'bottom',
    },
    -- accepted values:
    -- -1 true: generate hints
    -- -2 false: don't generate hints
    -- -3 [[multi line string]] - provide your own hints
    -- -4 fun(heads: Head[]): string - provide your own hints
    generate_hints = {
        normal = true,
        insert = true,
        extend = true,
        config = {
            -- determines how many columns are used to display the hints. If you leave this option nil, the number of columns will depend on the size of your window.
            column_count = nil,
            -- maximum width of a column.
            max_hint_length = 25,
        },
    },
}

return M
