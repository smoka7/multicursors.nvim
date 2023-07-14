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
        local I = require 'multicursors.insert_mode'
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
            insert_keys = {
                -- to change default lhs of key mapping change the key
                ['<CR>'] = { 
                    -- assigning nil to method exits from multi cursor mode 
                    method = I.Cr_method, 
                    -- description to show in hint window
                    desc = 'new line' 
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
    normal_keys = normal_keys,
    insert_keys = insert_keys
    extend_keys = extend_keys
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
| `e` | Enters extend mode |
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
| `Y` | Yanks the text from start of selection till end of line to `unnamed register` |
| `yy` | Yanks the line of selection to `unnamed register` |
| `z` | Aligns selections by adding space before selections |
| `Z` | Aligns selections by adding space at beginning of line |
| `d` | Deletes the text inside selections |
| `D` | Deletes the text from start of selection till end of line |
| `dd` | Deletes line of selections |
| `@` | Executes a macro at beginning of every selection |
| `.` | Reapets last change at the beginning of every selection |
| `,` | Clears All Selections except the main one |
| `:` | Prompts for a normal command and Executes it at beginning of every selection |
| `u` | Undo changes |
| `<C-r>` | Redo changes |

</details>

### Insert, Append and Change mode:

<details>
  <summary>Click me</summary>

| Key | Description |
|---|---|
| `<Esc>`   | Goes back to multicursor normal mode |
| `<C-c>`   | Goes back to multicursor normal mode |
| `<BS>`    | Deletes the char before the selections |
| `<Del>`   | Deletes the char under the selections |
| `<Left>`  | Moves the selections one char Left |
| `<Up>`    | Moves the selections one line Up |
| `<Right>` | Moves the selections one char Right |
| `<Down>`  | Moves the selections one line Down |
| `<Home>`  | Moves the selections to start of line |
| `<End>`   | Moves the selections to end of line |
| `<CR>`    | Insert one line below the selections |
| `<C-j>`   | Insert one line below the selections |
| `<C-v>`   | Pastes the text from system clipboard |
| `<C-r>`   | Insert the contents of a register |
| `<C-w>`   | Deletes one word before the selections |
| `<C-u>`   | Deletes froms start of selections till start of line |

</details>

### Extend mode
Once you enter the Extend mode, you have the ability to expand or shrink your selections using Vim motions.
The anchor represents one side of the selection and stays put, while the other side moves based on the performed motion.
<details>
  <summary>Click me</summary>

| Key | Description |
|---|---|
| `<Esc>`   | Goes back to multicursor normal mode |
| `c` | Prompts user for a motion and performs it |
| `o` | Toggles the anchor's side |
| `O` | Toggles the anchor's side |
| `w` | `[count]` word foreward |
| `e` | `[count]` foreward to end of word |
| `b` | `[count]` word backward |
| `h` | `[count]` char left |
| `j` | `[count]` char down |
| `k` | `[count]` char up |
| `l` | `[count]` char right |
| `$` | `[count]` to end of line |
| `^` | To the first non-blank character of the line |


</details>

## TODOS
- [ ] Move the selection by "ts" nodes (unclear)
- [ ] Support count + actions
- [ ] Completion works, but doesn't clear duplicates

## Acknowledgment
[vim-visual-multi](https://github.com/mg979/vim-visual-multi)
[hydra.nvim](https://github.com/anuvyklack/hydra.nvim)

This document is mostly written with Chatgpt.
