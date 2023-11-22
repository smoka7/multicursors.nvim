local T = {}

---@param a Selection
---@param b Selection
---@return boolean
local same_range = function(a, b)
    return a.col == b.col
        and a.row == b.row
        and a.end_col == b.end_col
        and a.end_row == b.end_row
end

--- Returns range of node
---@param node TSNode
---@return Selection
local get_node_range = function(node)
    ---@type Selection
    local node_range = {}
    node_range.row, node_range.col, node_range.end_row, node_range.end_col =
        node:range()
    return node_range
end

---Returns parrent of node in range of match
---@param match Selection
---@return Selection
T.extend_node = function(match)
    local parser = vim.treesitter.get_parser()
    local node = parser:named_node_for_range({
        match.row,
        match.col,
        match.end_row,
        match.end_col,
    }, { ignore_injections = false })

    if not node then
        return match
    end

    local node_range = get_node_range(node)
    if not same_range(match, node_range) then
        return node_range
    end

    while node:parent() do
        local parent = node:parent()
        if not parent then
            local sib = node:next_named_sibling()
            if not sib then
                return match
            end
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
    local parser = vim.treesitter.get_parser()
    local node = parser:named_node_for_range({
        match.row,
        match.col,
        match.end_row,
        match.end_col,
    }, { ignore_injections = false })

    if not node then
        return match
    end

    if node:child_count() < 1 then
        return match
    end

    local child = node:child(node:child_count() - 1)
    if not child then
        return match
    end

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
    local parser = vim.treesitter.get_parser()
    local node = parser:named_node_for_range({
        match.row,
        match.col,
        match.end_row,
        match.end_col,
    }, { ignore_injections = false })
    if not node then
        return match
    end

    if node:child_count() < 1 then
        return match
    end

    local child = node:child(0)
    if not child then
        return match
    end

    local node_range = get_node_range(child)
    if not same_range(match, node_range) then
        return node_range
    end

    return match
end

return T
