---@class Search
local search = require 'multicursors.search'

describe('search', function()
    before_each(function() end)

    it('finds next in line', function()
        local string =
            'Lorem ipsum dolor sit sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.'

        local match = search.find_next_match(string, 'sit', 0)
        assert.same({ start = 18, finish = 21 }, match)

        match = search.find_next_match(string, 'sit', 21)
        assert.same({ start = 22, finish = 25 }, match)

        match = search.find_next_match(string, 'sit', 25)
        assert.same(nil, match)
    end)

    it('finds prev in line', function()
        local string =
            'Lorem ipsum dolor sit sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.'

        local match = search.find_prev_match(string, 'sit', 50)
        assert.same({ start = 22, finish = 25 }, match)

        match = search.find_prev_match(string, 'sit', 22)
        assert.same({ start = 18, finish = 21 }, match)

        match = search.find_prev_match(string, 'sit', 18)
        assert.same(nil, match)
    end)
end)
