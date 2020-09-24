----------------------------------
-- Requires --
----------------------------------

local __constants = require("utils.constants")

----------------------------------
-- Technology --
----------------------------------

local combinatorTechnology = {
    type = "technology",
    name = __constants.names.wocCombinatorName,
    icon = __constants.imagePaths.technology,
    icon_size = 128,
    effects = {
        {
            type = "unlock-recipe",
            recipe = __constants.names.wocCombinatorName
        },
    },
    prerequisites = { "circuit-network" },
    unit = {
        count = 100,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 }
        },
        time = 15
    },
    order = "a-d-d"
}

data:extend({ combinatorTechnology })
