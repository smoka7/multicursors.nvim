---@class Search
local search = require 'multicursors.search'

local paragraph = {
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
}

describe('search', function()
    before_each(function() end)

    it('finds next in line', function()
        local string =
            'Lorem ipsum dolor sit sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.'

        local match = search.find_next_match(string, 'sit', 0)
        assert.same({ s_col = 18, e_col = 21 }, match)

        match = search.find_next_match(string, 'sit', 21)
        assert.same({ s_col = 22, e_col = 25 }, match)

        match = search.find_next_match(string, 'sit', 25)
        assert.same(nil, match)
    end)

    it('finds first multiline pattern', function()
        local string = table.concat(paragraph, '\n')
        local match = search.find_first_multiline(string, 'amet.\n Nisi anim')
        assert.same({ s_row = 1, s_col = 144, e_row = 2, e_col = 10 }, match)
        match = search.find_first_multiline(
            string,
            'ut officia. \n Sit irure elit esse'
        )
        assert.same(nil, match)
    end)

    it('finds last multiline pattern', function()
        local string = table.concat(paragraph, '\n')
        local match = search.find_last_multiline(string, 'amet.\n Nisi anim')
        assert.same({ s_row = 3, s_col = 144, e_row = 4, e_col = 10 }, match)
        match = search.find_last_multiline(
            string,
            'ut officia. \n Sit irure elit esse'
        )
        assert.same(nil, match)
    end)

    it('finds prev in line', function()
        local string =
            'Lorem ipsum dolor sit sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.'

        local match = search.find_prev_match(string, 'sit', 50)
        assert.same({ s_col = 22, e_col = 25 }, match)

        match = search.find_prev_match(string, 'sit', 22)
        assert.same({ s_col = 18, e_col = 21 }, match)

        match = search.find_prev_match(string, 'sit', 18)
        assert.same(nil, match)
    end)
end)
