----------------------------------
-- Requires --
----------------------------------

local __constants = require("utils.constants")

----------------------------------
-- Combinator item --
----------------------------------

-- Create a new combinator item from decider combinator
local combinatorItem = table.deepcopy(data.raw.item["decider-combinator"])

-- Add icon
combinatorItem.icon = __constants.imagePaths.combinatorIcon
combinatorItem.icon_size = 64
combinatorItem.icon_mipmaps = 4

combinatorItem.name = __constants.names.wocCombinatorName
combinatorItem.place_result = __constants.names.wocCombinatorName
combinatorItem.order = "c[combinators]-d[" .. __constants.names.wocCombinatorName .. "]"

data:extend({ combinatorItem })

----------------------------------
-- Hidden items for ports --
----------------------------------

local inputPortItem = table.deepcopy(data.raw.item["constant-combinator"])

-- Add icon
inputPortItem.icon = __constants.imagePaths.inputPortIcon
inputPortItem.icon_size = 64
inputPortItem.icon_mipmaps = 4

inputPortItem.name = __constants.names.inputPortName
inputPortItem.place_result = __constants.names.inputPortName
inputPortItem.flags = { "hidden" }

local outputPortItem = table.deepcopy(data.raw.item["constant-combinator"])

-- Add icon
outputPortItem.icon = __constants.imagePaths.outputPortIcon
outputPortItem.icon_size = 64
outputPortItem.icon_mipmaps = 4

outputPortItem.name = __constants.names.outputPortName
outputPortItem.place_result = __constants.names.outputPortName
outputPortItem.flags = { "hidden" }

data:extend({ inputPortItem, outputPortItem })
