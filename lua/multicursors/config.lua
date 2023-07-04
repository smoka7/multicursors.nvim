---@class Dictionary: { [string]: string }
local action_keys = {
    align_selections_before = 'z',
    align_selections_start = 'Z',
    append_mode = 'a',
    change_mode = 'c',
    clear_others = ',',
    create_down = 'j',
    create_up = 'k',
    delete = 'd',
    dot_repeat = '.',
    find_next = 'n',
    skip_find_next = 'q',
    skip_find_prev = 'Q',
    find_prev = 'N',
    goto_next = ']',
    goto_prev = '[',
    insert_mode = 'i',
    paste_after = 'p',
    paste_before = 'P',
    run_macro = '@',
    run_normal_command = ':',
    skip_create_down = 'J',
    skip_create_up = 'K',
    yank = 'y',
    --['dd'] = 'delete_line',
    --['D'] = 'delete_end',
    --['yy'] = 'yank_line',
    --['Y'] = 'yank_end',
}

--- TODO highlight custumization
---@class Config
local M = {
    DEBUG_MODE = false,
    create_commands = true, -- create Multicursor user commands
    updatetime = 50, -- selections get updated if this many milliseconds nothing is typed in the insert mode see :help updatetime
    keys = action_keys,
}

return M
