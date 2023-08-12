local api = vim.api
local assert = require 'luassert'
local selections = require 'multicursors.selections'
local paragraph = {
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
    'Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.',
    ' Nisi anim cupidatat excepteur officia.',
    's ごごろくじ a',
    '🫠🫠🫠🫠🫠',
}

describe('find and move ', function()
    before_each(function()
        vim.cmd [[enew]]
        api.nvim_buf_set_lines(0, 0, -1, false, paragraph)
    end)
    it('reduces selection', function()
        ---@type Selection
        local s = { id = 1, col = 2, end_col = 19, row = 4, end_row = 4 }
        local n = selections._get_reduced_selection(s, 'before')
        assert.same({ id = 1, col = 1, end_col = 2, row = 4, end_row = 4 }, n)
        -- passes reduce to assci char

        s = { id = 1, col = 5, end_col = 19, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'before')
        assert.same({ id = 1, col = 2, end_col = 5, row = 4, end_row = 4 }, n)
        -- passes reduce to unicode char

        s = { id = 1, col = 0, end_col = 19, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'before')
        assert.same({ id = 1, col = -1, end_col = 0, row = 4, end_row = 4 }, n)
        -- passes reduce to empty char

        s = { id = 1, col = 5, end_col = 19, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'after')
        assert.same({ id = 1, col = 5, end_col = 19, row = 4, end_row = 4 }, n)
        -- passes reduce to empty char

        s = { id = 1, col = 5, end_col = 17, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'after')
        assert.same({ id = 1, col = 17, end_col = 18, row = 4, end_row = 4 }, n)
        -- passes reduce to assci char

        s = { id = 1, col = 5, end_col = 14, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'after')
        assert.same({ id = 1, col = 14, end_col = 17, row = 4, end_row = 4 }, n)
        -- passes reduce to unicode char

        s = { id = 1, col = 5, end_col = 19, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'on')
        assert.same({ id = 1, col = 18, end_col = 19, row = 4, end_row = 4 }, n)
        -- passes reduce to assci char

        s = { id = 1, col = 5, end_col = 17, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'on')
        assert.same({ id = 1, end_col = 17, col = 14, row = 4, end_row = 4 }, n)
        -- passes reduce to unicode char

        s = { id = 1, col = 0, end_col = 0, row = 4, end_row = 4 }
        n = selections._get_reduced_selection(s, 'on')
        assert.same({ id = 1, col = -1, end_col = 0, row = 4, end_row = 4 }, n)
        -- passes reduce to empty char
    end)
end)
