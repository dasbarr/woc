----------------------------------
-- Requires --
----------------------------------

require("util")
local __constants = require("utils.constants")

----------------------------------
-- Sprites --
----------------------------------

local forwardHorizontalIconSprite = {
    filename = __constants.imagePaths.combinatorDisplays,
    name = __constants.names.forwardHorizontalIconSprite,
    type = "sprite",
    x = 0,
    y = 0,
    width = 15,
    height = 11,
    shift = util.by_pixel(0, -4.5),
    hr_version = {
        scale = 0.5,
        filename = __constants.imagePaths.combinatorDisplaysHR,
        x = 0,
        y = 0,
        width = 30,
        height = 22,
        shift = util.by_pixel(0, -4.5)
    }
}

local forwardVerticalIconSprite = {
    filename = __constants.imagePaths.combinatorDisplays,
    name = __constants.names.forwardVerticalIconSprite,
    type = "sprite",
    x = 15,
    y = 0,
    width = 15,
    height = 11,
    shift = util.by_pixel(0, -4.5),
    hr_version = {
        scale = 0.5,
        filename = __constants.imagePaths.combinatorDisplaysHR,
        x = 30,
        y = 0,
        width = 30,
        height = 22,
        shift = util.by_pixel(0, -4.5)
    }
}

local rotationIconSprite = {
    filename = __constants.imagePaths.combinatorDisplays,
    name = __constants.names.rotationIconSprite,
    type = "sprite",
    x = 30,
    y = 0,
    width = 15,
    height = 11,
    shift = util.by_pixel(0, -4.5),
    hr_version = {
        scale = 0.5,
        filename = __constants.imagePaths.combinatorDisplaysHR,
        x = 60,
        y = 0,
        width = 30,
        height = 22,
        shift = util.by_pixel(0, -4.5)
    }
}

data:extend({ forwardHorizontalIconSprite, forwardVerticalIconSprite, rotationIconSprite })

----------------------------------
-- Entity remnants --
----------------------------------

local combinatorRemnants = {
    type = "corpse",
    name = __constants.names.combinatorRemnantsName,
    icon = __constants.imagePaths.combinatorIcon,
    icon_size = 64, icon_mipmaps = 4,
    flags = {"placeable-neutral", "not-on-map"},
    subgroup = "circuit-network-remnants",
    order = "a-c-a",
    selection_box = { { -0.65, -0.5 }, { 0.65, 0.5 } },
    tile_width = 1,
    tile_height = 2,
    selectable_in_game = false,
    time_before_removed = 60 * 60 * 15, -- 15 minutes
    final_render_layer = "remnants",
    remove_on_tile_placement = false,
    animation = {
        filename = __constants.imagePaths.combinatorRemnants,
        line_length = 1,
        width = 78,
        height = 78,
        frame_count = 1,
        variation_count = 1,
        axially_symmetrical = false,
        direction_count = 4,
        shift = util.by_pixel(0, -1),
        hr_version = {
            filename = __constants.imagePaths.combinatorRemnantsHR,
            line_length = 1,
            width = 156,
            height = 156,
            frame_count = 1,
            variation_count = 1,
            axially_symmetrical = false,
            direction_count = 4,
            shift = util.by_pixel(0, -0.5),
            scale = 0.5
        }
    }
}

local portRemnants = table.deepcopy(combinatorRemnants)
portRemnants.name = __constants.names.portRemnantsName

-- Hide port remnants
portRemnants.selection_box = { { 0, 0 }, { 0, 0 } }
local portRemnantsAnimation = portRemnants.animation
portRemnantsAnimation.width = 1
portRemnantsAnimation.height = 1
portRemnantsAnimation.hr_version.width = 1
portRemnantsAnimation.hr_version.height = 1

data:extend({ combinatorRemnants, portRemnants })

----------------------------------
-- Base entity --
----------------------------------

-- Decider combinator parts will be used for our combinator creation
local deciderCombinator = table.deepcopy(data.raw["decider-combinator"]["decider-combinator"])

-- Make combinator base from electric-energy-interface to ensure that it uses electricity, can be rotated, but can't be opened
local combinatorBase = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
combinatorBase.name = __constants.names.wocCombinatorName

combinatorBase.animation = nil
combinatorBase.animations = nil
combinatorBase.picture = nil
combinatorBase.light = nil

-- Replace decider combinator graphics
combinatorBase.pictures = deciderCombinator.sprites
for _, sprite in pairs(combinatorBase.pictures) do
    local firstLayer = sprite.layers[1]
    
    firstLayer.filename = __constants.imagePaths.combinator
    firstLayer.hr_version.filename = __constants.imagePaths.combinatorHR
end

-- Set icon
combinatorBase.icon = __constants.imagePaths.combinatorIcon
combinatorBase.icon_size = 64
combinatorBase.icon_mipmaps = 4

combinatorBase.corpse = __constants.names.combinatorRemnantsName

combinatorBase.resistances = deciderCombinator.resistances
combinatorBase.minable = { mining_time = 0.1, result = __constants.names.wocCombinatorName }
combinatorBase.max_health = deciderCombinator.max_health
combinatorBase.healing_per_tick = deciderCombinator.healing_per_tick
combinatorBase.dying_explosion = deciderCombinator.dying_explosion
combinatorBase.fast_replaceable_group = ""

combinatorBase.collision_box = deciderCombinator.collision_box
combinatorBase.selection_box = { {-0.65, -0.5}, {0.65, 0.5} }

-- Setup energy parameters
combinatorBase.energy_source = {
    type = "electric",
    buffer_capacity = __constants.energyUsageKW .. "kJ", -- energy buffer should be the same as energy usage
    usage_priority = "secondary-input",
    input_flow_limit = "1MW",
    output_flow_limit = "0W",
}
combinatorBase.energy_production = "0W"
combinatorBase.energy_usage = __constants.energyUsageKW .. "kW"
combinatorBase.gui_mode = "none"

data:extend({ combinatorBase })

----------------------------------
-- Input port --
----------------------------------

-- Make combinator input port with constant combinator that doesn't have graphics
local inputPort = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
inputPort.name = __constants.names.inputPortName
inputPort.fast_replaceable_group = __constants.names.inputPortName
inputPort.flags = { "placeable-player", "player-creation", "placeable-off-grid", "not-deconstructable", "not-repairable" }
inputPort.mineable = nil
inputPort.max_health = 10000
inputPort.healing_per_tick = 10000
inputPort.collision_mask = { "not-colliding-with-itself" }
inputPort.collision_box = { {-0.0, -0.0}, {0.0, 0.0} }
inputPort.selection_box = { {-0.65, -0.5}, {0.65, 0.5} }
inputPort.item_slot_count = 0

inputPort.corpse = __constants.names.portRemnantsName

-- Set proper wire connection points
inputPort.circuit_wire_connection_points = {
    --north
    {
        shadow = { red = util.by_pixel(7, 1.5), green = util.by_pixel(25, -6) },
        wire = { red = util.by_pixel(-8.5, -10), green = util.by_pixel(9, -10.5) }
    },
    --east
    {
        shadow = { red = util.by_pixel(26.5, -1), green = util.by_pixel(20.5, 14) },
        wire = { red = util.by_pixel(4.5, -12.5), green = util.by_pixel(4.5, 2.5) }
    },
    --south
    {
        shadow =  { red = util.by_pixel(25.5, 19), green = util.by_pixel(7, 18.5) },
        wire = { red = util.by_pixel(9.5, 6.5), green = util.by_pixel(-8.5, 6.0) }
    },
    --west
    {
        shadow = { red = util.by_pixel(12, 14), green = util.by_pixel(12, -1) },
        wire = { red = util.by_pixel(-4, 2.5), green = util.by_pixel(-4, -12.5) }
    }
}

-- Make transparent pixel sprite definition, but don't add it to the game data directly - it will be used only in the current file
local transparentPixelSprite = {
    filename = __constants.imagePaths.transparentPixel,
    type = "sprite",
    x = 0,
    y = 0,
    width = 1,
    height = 1,
    hr_version = {
        filename = __constants.imagePaths.transparentPixel,
        x = 0,
        y = 0,
        width = 1,
        height = 1
    }
}

-- Make input port graphics invisible
for _, sprite in pairs(inputPort.sprites) do
    sprite.layers[1] = transparentPixelSprite
    
    -- Remove shadow
    sprite.layers[2] = nil
end

-- Disable activity lights
for direction, _ in pairs(inputPort.activity_led_sprites) do
    inputPort.activity_led_sprites[direction] = transparentPixelSprite
end

data:extend({ inputPort })

----------------------------------
-- Output port --
----------------------------------

-- Combinator output port will be similar to input port
local outputPort = table.deepcopy(inputPort)
outputPort.name = __constants.names.outputPortName
outputPort.fast_replaceable_group = __constants.names.outputPortName
outputPort.item_slot_count = 6 -- Factorio doesn't allow more than 6 filter slots on manipulators

-- Set proper wire connection points
outputPort.circuit_wire_connection_points = {
    --north
    {
        shadow = { red = util.by_pixel(6.5, 19), green = util.by_pixel(26, 19) },
        wire = { red = util.by_pixel(-9, 7.5), green = util.by_pixel(10, 7.5) }
    },
    --east
    {
        shadow = { red = util.by_pixel(9.5, 0.5), green = util.by_pixel(9.5, 14.5) },
        wire = { red = util.by_pixel(-6.5, -11), green = util.by_pixel(-6.5, 3) }
    },
    --south
    {
        shadow =  { red = util.by_pixel(25.5, 4), green = util.by_pixel(7, 4) },
        wire = { red = util.by_pixel(9.5, -8.5), green = util.by_pixel(-8.5, -8.5) }
    },
    --west
    {
        shadow = { red = util.by_pixel(23, 14), green = util.by_pixel(23, 1) },
        wire = { red = util.by_pixel(7, 2.5), green = util.by_pixel(7, -10.5) }
    }
}

data:extend({ outputPort })
