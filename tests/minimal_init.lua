local plenary_dir = os.getenv 'PLENARY_DIR' or '/tmp/plenary.nvim'
local hydra_dir = os.getenv 'PLENARY_DIR' or '/tmp/hydra.nvim'
local plenary_exists = vim.fn.isdirectory(plenary_dir) == 0
local hydra_exists = vim.fn.isdirectory(hydra_dir) == 0
if plenary_exists then
    vim.fn.system {
        'git',
        'clone',
        '--depth',
        '1',
        'https://github.com/nvim-lua/plenary.nvim',
        plenary_dir,
    }
end
if hydra_exists then
    vim.fn.system {
        'git',
        'clone',
        '--depth',
        '1',
        'https://github.com/smoka7/hydra.nvim',
        hydra_exists,
    }
end

vim.opt.rtp:append '.'
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(hydra_dir)

vim.cmd 'runtime plugin/plenary.vim'
require 'plenary.busted'
