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
    opts = {},
    keys = {
            {
                '<Leader>m',
                '<cmd>MCstart<cr>',
                desc = 'Create a selection for word under the cursor',
            },
        },
}
```

## Configuration

```lua
{
    DEBUG_MODE = false,
    create_commands = true, -- create Multicursor user commands
    updatetime = 50, -- selections get updated if this many milliseconds nothing is typed in the insert mode see :help updatetime
}
```

## Usage

| Command | Description |
|---|---|
| MCstart | Selects the word under cursor and starts listening for the actions. |
| MCpattern | Prompts for a pattern and selects every match in the buffer. |
| MCvisualPattern | Prompts for a pattern and selects every match in the visual selection. |
| MCunderCursor | Selects the char under cursor and starts listening for the actions. |
| MCclear | Clears all the selection. |

To enter multi cursor mode, use the `MCstart` command. Note that keys that aren't mapped will have no effect in this mode.

In multi cursor mode
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
| `d` | Delete the text inside selections |
| `@` | Executes a macro at beginning of every selection |
| `.` | Reapets last change at the beginning of every selection |
| `,` | Clears All Selections except the main one |
| `:` | Prompts for a normal command and Executes it at beginning of every selection |
| `u` | Undo changes |
| `<C-r>` | Redo changes |

In insert and append mode:
| Key | Description |
|---|---|
| `<Esc>`    | Clear the selections and go back to normal mode |
| `<BS>`    | Delete the char under the selections |
| `<Left>`  | Move the selections to Left |
| `<Up>`    | Move the selections to Up |
| `<Right>` | Move the selections to Right |
| `<Down>`  | Move the selections to Down |
| `<C-v>`  | Pastes the text from system clipboard |

## TODOS
- [ ] Move the selection by "ts" nodes (unclear)
- [ ] Move the selection by Vim motions (unclear)
- [ ] Support count + actions
- [ ] Handle overlapping selections (for now we merge them)
- [ ] Completion works, but doesn't clear duplicates
- [ ]  - Create a mod to show to the user
- [x]  - Clear other selections and only keep the main one
- [x] `[` - Go to the next selection
- [x] `]` - Go to the previous selection
- [ ] `z` - Align matches by inserting spaces before the first character of each selection
- [ ] `s` - Save matches
- [ ] `S` - Restore matches
- [ ] Should selection movements wrap vertically?
- [ ] Should selection movements wrap horizontally?
- [ ] Should `<bs>` wrap?
- [ ] Should folded lines get ignored when searching?
- [ ] show help window for mapping and registers ?

## Acknowledgment
[vim-visual-multi](https://github.com/mg979/vim-visual-multi)

This document is mostly written with Chatgpt.
