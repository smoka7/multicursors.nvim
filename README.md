# Multicursor.nvim [WIP]
The Multicursor Plugin for Neovim extends the native Neovim text editing capabilities, providing a more intuitive way to edit repetitive text with multiple cursors. With this plugin, you can easily create and manage multiple cursors, perform simultaneous edits, and execute commands on all cursors at once.

## Requirements

- Neovim >= **0.9.0**

## Installation

Install with your preferred package manager:

```lua
{
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
        'smoka7/hydra.nvim',
    },
    opts = function()
        local N = require 'multicursors.normal_mode'
        return {
            normal_keys = {
                -- to change default lhs of key mapping change the key
                ['b'] = { 
                    -- assigning nil to method exits from multi cursor mode 
                    method = N.clear_others, 
                    -- description to show in hint window
                    desc = 'Clear others' 
                },
            },
        }
    end,
    keys = {
            {
                '<Leader>m',
                '<cmd>MCstart<cr>',
                desc = 'Create a selection for word under the cursor',
            },
        },
}
```

## Default Configuration

<details>
  <summary>Click me</summary>

```lua
{
    DEBUG_MODE = false,
    create_commands = true, -- create Multicursor user commands
    updatetime = 50, -- selections get updated if this many milliseconds nothing is typed in the insert mode see :help updatetime
    normal_keys = {
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
        ['d'] = { method = N.delete, desc = 'Delete' },
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
        ['dd'] = { method = N.delete_line, desc = 'Delete line' },
    },
}
```
</details>

## Usage

| Command | Description |
|---|---|
| MCstart | Selects the word under cursor and starts listening for the actions. |
| MCvisual | Selects the last visual mode selection and starts listening for the actions. |
| MCpattern | Prompts for a pattern and selects every match in the buffer. |
| MCvisualPattern | Prompts for a pattern and selects every match in the visual selection. |
| MCunderCursor | Selects the char under cursor and starts listening for the actions. |
| MCclear | Clears all the selection. |

To enter multi cursor mode, use the one of above commands.

### Multi cursor mode
Note that keys which aren't mapped **do not affect other selections** .

<details>
  <summary>Click me</summary>

| Key | Description |
|---|---|
| `<Esc>` | Clear the selections and go back to normal mode |
| `<C-c>` | Clear the selections and go back to normal mode |
| `i` | Enters insert mode |
| `a` | Enters append mode |
| `c` | Deletes the text inside selections and starts insert mode |
| `n` | Finds the next match after the main selection |
| `N` | Finds the previous match before the main selection |
| `q` | Skips the current selection and finds the next one |
| `Q` | Skips the current selection and finds the previous one |
| `]` | Swaps the main selection with next selection |
| `[` | Swaps the main selection with previous selection |
| `j` | Creates a selection on the char below the cursor |
| `J` | Skips the current selection and Creates a selection on the char below |
| `k` | Creates a selection on the char above the cursor |
| `K` | Skips the current selection and Creates a selection on the char above |
| `p` | Puts the text inside `unnamed register` before selections |
| `P` | Puts the text inside `unnamed register` after selections |
| `y` | Yanks the text inside selection to `unnamed register` |
| `z` | Aligns selections by adding space before selections |
| `Z` | Aligns selections by adding space at beginning of line |
| `d` | Delete the text inside selections |
| `@` | Executes a macro at beginning of every selection |
| `.` | Reapets last change at the beginning of every selection |
| `,` | Clears All Selections except the main one |
| `:` | Prompts for a normal command and Executes it at beginning of every selection |
| `u` | Undo changes |
| `<C-r>` | Redo changes |

</details>

### insert and append mode:

<details>
  <summary>Click me</summary>

| Key | Description |
|---|---|
| `<Esc>`    | Clear the selections and go back to normal mode |
| `<BS>`    | Delete the char under the selections |
| `<Left>`  | Move the selections to Left |
| `<Up>`    | Move the selections to Up |
| `<Right>` | Move the selections to Right |
| `<Down>`  | Move the selections to Down |
| `<C-v>`  | Pastes the text from system clipboard |

</details>

## TODOS
- [ ] Move the selection by "ts" nodes (unclear)
- [ ] Move the selection by Vim motions (unclear)
- [ ] Support count + actions
- [ ] Handle overlapping selections (for now we merge them)
- [ ] Completion works, but doesn't clear duplicates
- [ ] Should selection movements wrap vertically?
- [ ] Should selection movements wrap horizontally?
- [ ] Should `<bs>` wrap?
- [ ] Should folded lines get ignored when searching?

## Acknowledgment
[vim-visual-multi](https://github.com/mg979/vim-visual-multi)
[hydra.nvim](https://github.com/anuvyklack/hydra.nvim)

This document is mostly written with Chatgpt.
