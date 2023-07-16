---@class Search
local search = require 'multicursors.search'
local utils = require 'multicursors.utils'
local normal_mode = require 'multicursors.normal_mode'
local api = vim.api

local paragraph = {
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
}

describe('search', function()
    before_each(function()
        vim.cmd [[enew]]
        api.nvim_buf_set_lines(0, 0, 4, false, paragraph)
    end)

    it('finds cursor_word', function()
        api.nvim_win_set_cursor(0, { 1, 1 })
        local word = search.find_cursor_word()
        assert.same(word, {
            s_row = 0,
            e_row = 0,
            s_col = 0,
            e_col = 5,
        })
        assert.same(vim.b.MultiCursorPattern, 'Lorem')

        api.nvim_win_set_cursor(0, { 1, 5 })
        word = search.find_cursor_word()
        assert.same(word, {
            s_row = 0,
            e_row = 0,
            s_col = 6,
            e_col = 5,
        })
        assert.same(vim.b.MultiCursorPattern, '')
    end)

    it('finds all matches', function()
        local content = api.nvim_buf_get_lines(0, 0, 4, false)
        search.find_all_matches(content, 'Lorem', 0, 0)
        local main = utils.get_main_selection()
        assert.same(main.row, 2)
        assert.same(main.col, 101)
        assert.same(main.end_col, 106)
        assert.same(main.end_row, 2)
        local selesctions = utils.get_all_selections()
        assert.same(#selesctions, 3)
    end)

    it('finds next in line', function()
        local string =
            'Lorem ipsum dolor sit sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.'
        ---@type SearchContext
        local ctx = { text = string, pattern = 'sit', offset = 0, row = 1 }
        local match = search.find_next_match(ctx)
        assert.same({ s_row = 0, e_row = 0, s_col = 18, e_col = 21 }, match)

        ctx.offset = 21
        match = search.find_next_match(ctx)
        assert.same({ s_row = 0, e_row = 0, s_col = 22, e_col = 25 }, match)

        ctx.offset = 25
        match = search.find_next_match(ctx)
        assert.same(nil, match)
    end)

    it('finds prev in line', function()
        local string =
            'Lorem ipsum dolor sit sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.'

        local ctx = { text = string, pattern = 'sit', till = 50, row = 1 }
        local match = search.find_prev_match(ctx)
        assert.same({ s_row = 0, e_row = 0, s_col = 22, e_col = 25 }, match)

        ctx.till = 22
        match = search.find_prev_match(ctx)
        assert.same({ s_row = 0, e_row = 0, s_col = 18, e_col = 21 }, match)

        ctx.till = 18
        match = search.find_prev_match(ctx)
        assert.same(nil, match)
    end)

    it('skips and creates a cursor up', function()
        api.nvim_win_set_cursor(0, { 3, 36 })
        normal_mode.new_under_cursor()
        search.create_up(true)
        local main = utils.get_main_selection()
        assert.same(main.row, 1)
        assert.same(main.col, 36)
        assert.same(main.end_col, 37)
        assert.same(main.end_row, 1)
        local selesctions = utils.get_all_selections()
        assert.same(#selesctions, 0)
    end)

    it('creates a cursor up', function()
        api.nvim_win_set_cursor(0, { 3, 36 })
        normal_mode.new_under_cursor()
        search.create_up(false)
        local main = utils.get_main_selection()
        assert.same(main.row, 1)
        assert.same(main.col, 36)
        assert.same(main.end_col, 37)
        assert.same(main.end_row, 1)
        search.create_up(false)
        main = utils.get_main_selection()
        assert.same(main.row, 0)
        assert.same(main.col, 36)
        assert.same(main.end_col, 37)
        assert.same(main.end_row, 0)
        local selesctions = utils.get_all_selections()
        assert.same(#selesctions, 2)
    end)

    it('skips and creates a cursor below', function()
        api.nvim_win_set_cursor(0, { 3, 36 })
        normal_mode.new_under_cursor()
        search.create_down(true)
        local main = utils.get_main_selection()
        assert.same(main.row, 3)
        assert.same(main.col, 36)
        assert.same(main.end_col, 37)
        assert.same(main.end_row, 3)
        local selesctions = utils.get_all_selections()
        assert.same(#selesctions, 0)
    end)

    it('creates a cursor below', function()
        api.nvim_win_set_cursor(0, { 3, 36 })
        normal_mode.new_under_cursor()
        search.create_down(false)
        local main = utils.get_main_selection()
        assert.same(main.row, 3)
        assert.same(main.col, 36)
        assert.same(main.end_col, 37)
        assert.same(main.end_row, 3)
        local selesctions = utils.get_all_selections()
        assert.same(#selesctions, 1)
    end)

    it('find a multiline pattern before cursor ', function()
        api.nvim_win_set_cursor(0, { 1, 5 })
        local match =
            search.multiline_string('amet.\\n Nisi anim', utils.position.before)
        assert.same({
            s_row = 2,
            s_col = 144,
            e_row = 3,
            e_col = 10,
        }, match)
        api.nvim_win_set_cursor(0, { 3, 10 })
        match =
            search.multiline_string('amet.\\n Nisi anim', utils.position.before)
        assert.same({
            s_row = 0,
            s_col = 144,
            e_row = 1,
            e_col = 10,
        }, match)
    end)

    it('find a multiline pattern after cursor ', function()
        api.nvim_win_set_cursor(0, { 1, 5 })
        local match =
            search.multiline_string('amet.\\n Nisi anim', utils.position.after)
        assert.same({
            s_row = 0,
            s_col = 144,
            e_row = 1,
            e_col = 10,
        }, match)
        api.nvim_win_set_cursor(0, { 2, 5 })
        match =
            search.multiline_string('amet.\\n Nisi anim', utils.position.after)
        assert.same({
            s_row = 2,
            s_col = 144,
            e_row = 3,
            e_col = 10,
        }, match)
    end)
end)
