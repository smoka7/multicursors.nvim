---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

- [ ] Did you check Readme and existing issues?
    
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
```lua 
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--depth',
        '1',
        '--filter=blob:none',
        '--single-branch',
        'https://github.com/folke/lazy.nvim.git',
        lazypath,
    }
end

vim.opt.runtimepath:prepend(lazypath)
require('lazy').setup({
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'smoka7/hydra.nvim',
    },
    opts = {},
    cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
}, opts)
-- more necessary steps to reproduce


```
**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Nvim version:**

**Multicursor version:**

**Additional context**
Add any other context about the problem here.
