local api = vim.api
local utils = require 'multicursors.utils'
local assert = require 'luassert'
local search = require 'multicursors.search'
local extend_mode = require 'multicursors.extend_mode'
local paragraph = {
    'lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
    's ごごろくじ a',
    '🫠🫠🫠🫠🫠',
}

describe('extend mode', function()
    before_each(function()
        vim.cmd [[enew]]
        api.nvim_buf_set_lines(0, 0, -1, false, paragraph)
        local buffer = api.nvim_buf_get_lines(0, 0, -1, false)
        search.find_all_matches(buffer, 'amet', 0, 0)
    end)

    after_each(function()
        vim.cmd.bdelete { bang = true }
    end)

    it('togggles anchor', function()
        vim.b.MultiCursorAnchorStart = false
        extend_mode.o_method()
        assert.equal(true, vim.b.MultiCursorAnchorStart)
        extend_mode.o_method()
        assert.equal(false, vim.b.MultiCursorAnchorStart)
    end)

    it('extends foreward', function()
        local selections = utils.get_all_selections()
        vim.b.MultiCursorAnchorStart = true
        extend_mode.e_method()
        selections = utils.get_all_selections()
        assert.same(
            { id = 1, col = 22, end_col = 27, row = 0, end_row = 0 },
            selections[1]
        )
    end)

    it('extends backward', function()
        local selections = utils.get_all_selections()
        vim.b.MultiCursorAnchorStart = false
        extend_mode.b_method()
        selections = utils.get_main_selection()
        assert.same(
            { id = 1, col = 131, end_col = 148, row = 0, end_row = 0 },
            selections
        )
    end)

    it('switches backward', function()
        local selections = utils.get_all_selections()
        vim.b.MultiCursorAnchorStart = false
        extend_mode.dollar_method()
        selections = utils.get_all_selections()
        assert.same(
            { id = 1, col = 26, end_col = 149, row = 0, end_row = 0 },
            selections[1]
        )
        assert.equal(true, vim.b.MultiCursorAnchorStart)
    end)

    it('switches foreward', function()
        local selections = utils.get_all_selections()
        vim.b.MultiCursorAnchorStart = true
        extend_mode.caret_method()
        selections = utils.get_main_selection()
        assert.same(
            { id = 1, col = 1, end_col = 144, row = 0, end_row = 0 },
            selections
        )
        assert.equal(false, vim.b.MultiCursorAnchorStart)
    end)
end)
