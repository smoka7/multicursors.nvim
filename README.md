# Multicursor.nvim [WIP]
The Multicursor Plugin for Neovim extends the native Neovim text editing capabilities, providing a more intuitive way to edit repetitive text with multiple cursors. With this plugin, you can easily create and manage multiple cursors, perform simultaneous edits, and execute commands on all cursors at once.

## Requirements

- Neovim >= **0.9.0**

## Installation

Install with your preferred package manager:

```lua
{
    "smoka7/multicursor.nvim",
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
{}
```

## Usage

| Command | Description |
|---|---|
| MCstart | Selects the word under cursor and starts listening for the actions. |
| MCclear | Clears all the selection. |

To enter multi cursor mode, use the `MCstart` command. Note that keys that aren't mapped will have no effect in this mode.

In multi cursor mode
| Key | Description |
|---|---|
| `<Esc>` | Clear the selections and go back to normal mode |
| `i` | Enters insert mode |
| `a` | Enters append mode |
| `n` | Moves to the next match after the main selection |
| `N` | Moves to the previous match before the main selection |
| `q` | Skips the current match and moves to the next one |
| `Q` | Skips the current match and moves to the previous one |
| `@` | Executes a macro at beginning of every selection |

In insert and append mode:
| Key | Description |
|---|---|
| `<Esc>`    | Clear the selections and go back to normal mode |
| `<BS>`    | Delete the char under the selections |
| `<Left>`  | Move the selections to Left |
| `<Up>`    | Move the selections to Up |
| `<Right>` | Move the selections to Right |
| `<Down>`  | Move the selections to Down |

## TODOS
- [x] Get the word under the cursor
- [x] Go to the next match
- [x] Move the main selection to the next match
- [x] Wrap around the buffer when searching for a match
- [x] Skip forward to the next match
- [x] Go to the previous match and skip it
- [x] Move the selections 
- [ ] Select all matches of a pattern within the visual selection
- [ ] Move the selection by "ts" nodes (unclear)
- [ ] Move the selection by Vim motions (unclear)
- [ ] Support count + actions
- [ ] Handle overlapping selections (for now we merge them)
- [x] Enter insert mode
- [x] Enter append mode
- [ ] Enter change mode
- [ ] Completion works, but doesn't clear duplicates
- [x] Live update matches with every character
- [x] Pasting (insert mode works)
- [x] Macros
- [ ] Yanking
- [ ] Deleting
- [ ]  - Create a mod to show to the user
- [ ]  - Create a selection in the next line
- [ ]  - Create a selection in the previous line
- [ ]  - Clear other selections and only keep the main one
- [x]  - Clear all matches
- [x] `i` - Enter insert mode
- [x] `a` - Enter append mode
- [x] `n` - Go to the next match after the main selection
- [x] `N` - Go to the previous match before the main selection
- [x] `q` - Skip the current match and go to the next one
- [x] `Q` - Skip the current match and go to the previous one
- [x] `@` - Run a macro on every selection
- [ ] `[` - Go to the next selection
- [ ] `]` - Go to the previous selection
- [ ] `z` - Align matches by inserting spaces before the first character of each selection
- [ ] `s` - Save matches
- [ ] `S` - Restore matches
- [ ] Should selection movements wrap vertically?
- [ ] Should selection movements wrap horizontally?
- [ ] Should `<bs>` wrap?
- [ ] Should folded lines get ignored when searching?

## Acknowledgment
[vim-visual-multi](https://github.com/mg979/vim-visual-multi)

This document is mostly written with Chatgpt.
