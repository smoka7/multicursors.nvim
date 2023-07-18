local api = vim.api
local assert = require 'luassert'
local utils = require 'multicursors.utils'
local search = require 'multicursors.search'
local normal_mode = require 'multicursors.normal_mode'

local paragraph = {
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
}
describe('find and move ', function()
    before_each(function()
        vim.cmd [[enew]]
        api.nvim_buf_set_lines(0, 0, 4, false, paragraph)
    end)

    it('finds selections and moves between them', function()
        api.nvim_win_set_cursor(0, { 1, 1 })
        search.find_cursor_word()

        local main = utils.get_main_selection()
        assert.is_not(main, nil)
        assert.same(main.row, 0)
        assert.same(main.col, 0)
        assert.same(main.end_col, 5)
        assert.same(main.end_row, 0)

        normal_mode.find_next()
        local cursor = api.nvim_win_get_cursor(0)
        local selections = utils.get_all_selections()
        assert.same(cursor, { 1, 105 })
        assert.equal(#selections, 1)

        normal_mode.skip_find_next()
        selections = utils.get_all_selections()
        assert.equal(#selections, 1)

        normal_mode.find_prev()
        cursor = api.nvim_win_get_cursor(0)
        selections = utils.get_all_selections()
        assert.same(cursor, { 1, 101 })
        assert.equal(#selections, 2)

        normal_mode.skip_find_prev()
        selections = utils.get_all_selections()
        cursor = api.nvim_win_get_cursor(0)
        assert.same(cursor, { 1, 0 })
        assert.equal(#selections, 1)

        normal_mode.find_next()
        selections = utils.get_all_selections()
        assert.equal(#selections, 2)

        normal_mode.goto_next()
        cursor = api.nvim_win_get_cursor(0)
        assert.same(cursor, { 3, 0 })

        normal_mode.goto_prev()
        cursor = api.nvim_win_get_cursor(0)
        assert.same(cursor, { 1, 101 })

        normal_mode.skip_goto_next()
        selections = utils.get_all_selections()
        cursor = api.nvim_win_get_cursor(0)
        assert.equal(#selections, 1)
        assert.same(cursor, { 3, 0 })

        normal_mode.skip_goto_prev()
        selections = utils.get_all_selections()
        cursor = api.nvim_win_get_cursor(0)
        assert.equal(#selections, 0)
        assert.same(cursor, { 1, 0 })
    end)
end)

describe('normal actions', function()
    before_each(function()
        vim.cmd [[enew]]
        api.nvim_buf_set_lines(0, 0, 4, false, paragraph)
        api.nvim_win_set_cursor(0, { 1, 1 })
        search.find_all_matches(
            api.nvim_buf_get_lines(0, 0, -1, false),
            'lorem',
            0,
            0
        )
    end)

    it('can clear others', function()
        normal_mode.clear_others()
        assert.same(0, #utils.get_all_selections())
    end)

    it('can paste at selections', function()
        local paste = 'bender'
        vim.fn.setreg('', paste)
        normal_mode.paste_after()

        local found = vim.fn.search(paste)
        assert.same(found, 1)
        assert.same(api.nvim_win_get_cursor(0), { 1, 5 })

        found = vim.fn.search(paste)
        assert.same(found, 1)
        assert.same(api.nvim_win_get_cursor(0), { 1, 112 })
    end)

    it('can delete the selections', function()
        normal_mode.delete()

        local found = vim.fn.search(lorem)
        assert.same(found, 0)
    end)
end)
