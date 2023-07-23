
---@class Match
---@field s_row integer start row
---@field s_col integer start column
---@field e_row integer end row
---@field e_col integer end column

---@class Action
---@field method function?
---@field opts HeadOpts

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

---@class Head
---@field [1] string
---@field [2] string | function | nil
---@field [3] HeadOpts

---@class HeadOpts
---@field public private? boolean
---@field exit? boolean
---@field exit_before? boolean
---@field on_key? boolean
---@field mode? string[]
---@field silent? boolean
---@field expr? boolean
---@field nowait? boolean
---@field remap? boolean
---@field desc? string
