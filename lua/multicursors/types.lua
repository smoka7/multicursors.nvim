
---@class Match
---@field s_row integer start row
---@field s_col integer start column
---@field e_row integer end row
---@field e_col integer end column

---@class Action
---@field method function?
---@field opts table

---@class Point
---@field row integer
---@field col integer

---@class Selection
---@field id integer
---@field row integer
---@field col integer
---@field end_row integer
---@field end_col integer

---@class SearchContext
---@field pattern string
---@field text string
---@field row integer
---@field offset integer
---@field till integer
---@field skip boolean
