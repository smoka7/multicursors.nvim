local utils = require 'multicursors.utils'
local search = require 'multicursors.search'
local insert_mode = require 'multicursors.insert_mode'
local normal_mode = require 'multicursors.normal_mode'
local config = require 'multicursors.config'
local api = vim.api
local assert = require 'luassert'

local paragraph = {
    'lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi lorem pariatur mollit ex esse exercitation amet.',
    ' nisi anim cupidatat excepteur officia.',
    'lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi lorem pariatur mollit ex esse exercitation amet.',
    ' nisi anim cupidatat excepteur officia.',
}

describe('inserts mode', function()
    before_each(function()
        vim.cmd [[enew]]
        api.nvim_buf_set_lines(0, 0, -1, false, paragraph)
        local buffer = api.nvim_buf_get_lines(0, 0, -1, false)
        search.find_all_matches(buffer, 'lorem', 0, 0)
    end)

    after_each(function()
        vim.cmd.bdelete { bang = true }
    end)

    it('appends text', function()
        local selections = utils.get_all_selections()
        assert.equal(#selections, 3)

        insert_mode.append(config)
        utils.call_on_selections(function(selection)
            assert.equal(selection.end_col - selection.col, 1)
        end)

        vim.cmd 'normal! ipot'
        insert_mode.exit()

        local buffer = api.nvim_buf_get_lines(0, 0, -1, false)
        utils.clear_selections()
        search.find_all_matches(buffer, 'lorempot', 0, 0)
        selections = utils.get_all_selections()
        assert.equal(#selections, 3)
    end)

    it('inserts text', function()
        local selections = utils.get_all_selections()
        assert.equal(#selections, 3)

        insert_mode.insert(config)
        vim.cmd 'normal! ipot'
        insert_mode.exit()

        local buffer = api.nvim_buf_get_lines(0, 0, -1, false)
        utils.clear_selections()
        search.find_all_matches(buffer, 'potlorem', 0, 0)
        selections = utils.get_all_selections()
        assert.equal(#selections, 3)
    end)

    it('changes text', function()
        local selections = utils.get_all_selections()
        assert.equal(#selections, 3)

        normal_mode.change(config)
        vim.cmd 'normal! ipot'
        insert_mode.exit()

        local buffer = api.nvim_buf_get_lines(0, 0, -1, false)
        utils.clear_selections()
        search.find_all_matches(buffer, 'pot', 0, 0)
        selections = utils.get_all_selections()
        assert.equal(#selections, 3)

        utils.clear_selections()
        search.find_all_matches(buffer, 'lorem', 0, 0)
        selections = utils.get_all_selections()
        assert.equal(#selections, 0)
    end)

    it('deletes a char', function()
        local selections = utils.get_all_selections()
        assert.equal(#selections, 3)

        insert_mode.append(config)
        insert_mode.BS_method()
        insert_mode.exit()

        local buffer = api.nvim_buf_get_lines(0, 0, -1, false)
        utils.clear_selections()
        search.find_all_matches(buffer, 'lore', 0, 0)
        selections = utils.get_all_selections()
        assert.equal(#selections, 3)

        utils.clear_selections()
        search.find_all_matches(buffer, 'lorem', 0, 0)
        selections = utils.get_all_selections()
        assert.equal(#selections, 0)
    end)
end)
