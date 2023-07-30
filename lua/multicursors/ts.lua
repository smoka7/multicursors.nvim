local parsers = require 'nvim-treesitter.parsers'

local T = {}

---@param a Selection
---@param b Selection
---@return boolean
local same_range = function(a, b)
    return a == b
end

--- Returns range of node
---@param node TSNode
---@return Selection
local get_node_range = function(node)
    ---@type Selection
    local node_range = {}
    node_range.row, node_range.col, node_range.end_row, node_range.end_col =
        vim.treesitter.get_node_range(node)
    return node_range
end

---Returns parrent of node in range of match
---@param match Selection
---@return Selection
T.extend_node = function(match)
    local root = parsers.get_parser():parse()[1]:root()

    ---@type TSNode
    local node = root:named_descendant_for_range(
        match.row,
        match.col,
        match.end_row,
        match.end_col
    )

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
---@param match Selection
---@return Selection
T.get_last_child = function(match)
    local root = parsers.get_parser():parse()[1]:root()

    ---@type TSNode
    local node = root:named_descendant_for_range(
        match.row,
        match.col,
        match.end_row,
        match.end_col
    )
    if node:named_child_count() < 1 then
        return match
    end
    local child = node:named_child(node:named_child_count() - 1)

    local node_range = get_node_range(child)
    if not same_range(match, node_range) then
        return node_range
    end

    return match
end

--- Returns first child of node in range of match
---@param match Selection
---@return Selection
T.get_first_child = function(match)
    local root = parsers.get_parser():parse()[1]:root()

    ---@type TSNode
    local node = root:named_descendant_for_range(
        match.row,
        match.col,
        match.end_row,
        match.end_col
    )

    if node:named_child_count() < 1 then
        return match
    end

    local child = node:named_child(0)
    local node_range = get_node_range(child)
    if not same_range(match, node_range) then
        return node_range
    end

    return match
end

return T
