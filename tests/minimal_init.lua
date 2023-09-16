local plenary_dir = os.getenv 'PLENARY_DIR' or '/tmp/plenary.nvim'
local hydra_dir = os.getenv 'HYDRA_DIR' or '/tmp/hydra.nvim'

local plenary_exists = vim.fn.isdirectory(plenary_dir) == 0
local hydra_exists = vim.fn.isdirectory(hydra_dir) == 0

---@param dir string
---@param url string
local function clone(url, dir)
    vim.fn.system {
        'git',
        'clone',
        '--depth',
        '1',
        url,
        dir,
    }
end

if plenary_exists then
    clone('https://github.com/nvim-lua/plenary.nvim', plenary_dir)
end

if hydra_exists then
    clone('https://github.com/smoka7/hydra.nvim', hydra_dir)
end

vim.opt.directory = ''
vim.opt.rtp:append '.'
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(hydra_dir)

vim.cmd.runtime { 'plugin/plenary.vim', bang = true }
vim.cmd.runtime { 'plugin/hydra.nvim', bang = true }
