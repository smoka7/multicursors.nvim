local parsers = require 'nvim-treesitter.parsers'

local T = {}

---@param a Match
---@param b Match
---@return boolean
local same_range = function(a, b)
    return a.s_col == b.s_col
        and a.e_row == b.e_row
        and a.e_col == b.e_col
        and a.s_row == b.s_row
end

--- Returns range of node
---@param node TSNode
---@return Match
local get_node_range = function(node)
    ---@type Match
    local node_range = {}
    node_range.s_row, node_range.s_col, node_range.e_row, node_range.e_col =
        vim.treesitter.get_node_range(node)
    return node_range
end

local root = nil

---Returns parrent of node in range of match
---@param match Match
---@return Match
T.extend_node = function(match)
    if not root then
        root = parsers.get_parser():parse()[1]:root()
    end
    ---@type TSNode
    local node = root:named_descendant_for_range(
        match.s_row,
        match.s_col,
        match.e_row,
        match.e_col
    )

    ---@type Match
    local node_range = get_node_range(node)
    if not same_range(match, node_range) then
        return node_range
    end

    while node:parent() do
        local parent = node:parent()
        if not parent then
            local sib = node:next_named_sibling()
            node_range = get_node_range(sib)
            if not same_range(match, node_range) then
                return node_range
            end

            return match
        end
        node_range = get_node_range(parent)
        if not same_range(match, node_range) then
            return node_range
        end
        node = parent
    end

    return match
end

--- Returns last child of node in range of match
---@param match Match
---@return Match
T.get_last_child = function(match)
    --local root = parsers.get_parser():parse()[1]:root()

    if not root then
        root = parsers.get_parser():parse()[1]:root()
    end
    ---@type TSNode
    local node = root:named_descendant_for_range(
        match.s_row,
        match.s_col,
        match.e_row,
        match.e_col
    )
    if node:named_child_count() < 1 then
        return match
    end
    local child = node:named_child(node:named_child_count() - 1)
    ---@type Match
    local node_range = get_node_range(child)
    if not same_range(match, node_range) then
        return node_range
    end

    return match
end

--- Returns first child of node in range of match
---@param match Match
---@return Match
T.get_first_child = function(match)
    if not root then
        root = parsers.get_parser():parse()[1]:root()
    end

    ---@type TSNode
    local node = root:named_descendant_for_range(
        match.s_row,
        match.s_col,
        match.e_row,
        match.e_col
    )

    if node:named_child_count() < 1 then
        return match
    end

    local child = node:named_child(0)
    ---@type Match
    local node_range = get_node_range(child)
    if not same_range(match, node_range) then
        return node_range
    end

    return match
end
return T
