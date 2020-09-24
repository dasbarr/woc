----------------------------------
-- Requires --
----------------------------------

local __constants = require("utils.constants")

----------------------------------
-- Recipe --
----------------------------------

local combinatorRecipe = {
    type = "recipe",
    enabled = "false",
    name = __constants.names.wocCombinatorName,
    result = __constants.names.wocCombinatorName,
    ingredients = {
        { "copper-cable", 5 },
        { "electronic-circuit", 5 }
    }
}

data:extend({ combinatorRecipe })
