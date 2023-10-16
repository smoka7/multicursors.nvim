
---@class Action
---@field method function?| false -- nil value creates a exit head false value remove's the mapping
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

---@class GenerateHints
---@field normal boolean|string| fun(heads: Head[]): string
---@field insert boolean|string| fun(heads: Head[]): string
---@field extend boolean|string| fun(heads: Head[]): string
---@field config GenerateHintsConfig

---@class GenerateHintsConfig
---@field column_count? integer
---@field max_hint_length integer

---@class Config
---@field generate_hints GenerateHints
