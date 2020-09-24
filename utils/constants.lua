local __constants = {
    names = {},
    imagePaths = {},
    settings = {},
    enums = {}
}

----------------------------------
-- Names --
----------------------------------

__constants.names.wocCombinatorName = "woc-combinator"
__constants.names.inputPortName = "woc-combinator-input"
__constants.names.outputPortName = "woc-combinator-output"

__constants.names.combinatorRemnantsName = "woc-combinator-remnants"
__constants.names.portRemnantsName = "woc-port-remnants"

__constants.names.inputCheckIntervalSettingName = __constants.names.wocCombinatorName .. "_inputCheckInterval"
__constants.names.outputUpdateIntervalSettingName = __constants.names.wocCombinatorName .. "_outputUpdateInterval"
__constants.names.maxNumOutputSignalsSettingName = __constants.names.wocCombinatorName .. "_maxNumOutputSignals"
__constants.names.preserveSignalCountSettingName = __constants.names.wocCombinatorName .. "_preserveSignalCount"
__constants.names.inputOutputIconsAllowedSettingName = __constants.names.wocCombinatorName .. "_inputOutputIconsAllowed"

__constants.names.forwardHorizontalIconSprite = __constants.names.wocCombinatorName .. "_forwardHorizontalIconSprite"
__constants.names.forwardVerticalIconSprite = __constants.names.wocCombinatorName .. "_forwardVerticalIconSprite"
__constants.names.rotationIconSprite = __constants.names.wocCombinatorName .. "_rotationIconSprite"

----------------------------------
-- Image paths --
----------------------------------

local basePath = "__woc__"

__constants.imagePaths.combinator = basePath .. "/graphics/entity/woc-combinator.png"
__constants.imagePaths.combinatorHR = basePath .. "/graphics/entity/hr-woc-combinator.png"

__constants.imagePaths.combinatorDisplays = basePath .. "/graphics/entity/woc-combinator-displays.png"
__constants.imagePaths.combinatorDisplaysHR = basePath .. "/graphics/entity/hr-woc-combinator-displays.png"

__constants.imagePaths.combinatorRemnants = basePath .. "/graphics/entity/remnants/woc-combinator-remnants.png"
__constants.imagePaths.combinatorRemnantsHR = basePath .. "/graphics/entity/remnants/hr-woc-combinator-remnants.png"

__constants.imagePaths.combinatorIcon = basePath .. "/graphics/icons/woc-combinator-icon.png"
__constants.imagePaths.inputPortIcon = basePath .. "/graphics/icons/woc_input_port_icon.png"
__constants.imagePaths.outputPortIcon = basePath .. "/graphics/icons/woc_output_port_icon.png"

__constants.imagePaths.technology = basePath .. "/graphics/technology/woc-combinator-technology.png"

__constants.imagePaths.transparentPixel = basePath .. "/graphics/auxiliary/transparent-pixel.png"

----------------------------------
-- Intervals --
----------------------------------

-- After that amount of time (in ticks) combinator will use new portion of energy
__constants.energyConsumptionInterval = 15

-- After that amount of time (in ticks) combinator will check if input was changed or not
__constants.settings.inputCheckInterval = 15
-- After that amount of time (in ticks) combinator will update output (if output rotation is needed)
__constants.settings.outputUpdateInterval = 60

----------------------------------
-- Misc --
----------------------------------

-- How much energy combinator uses per second
__constants.energyUsageKW = 2

-- Size of combinator output 'window' - how much signals will be sent to output at one moment
__constants.settings.maxNumOutputSignals = 4
-- If true, combinator will output signals with their counts, otherwise if will output signals with '1' count
__constants.settings.preserveSignalCount = true

-- If true, input-output icons (yellow triangles) will be shown
__constants.settings.inputOutputIconsAllowed = true

----------------------------------
-- Enums --
----------------------------------

__constants.enums.OutputState = {
    None = 1,    -- No output
    Forward = 2, -- Combinator just forwards input
    Rotation = 3 -- Combinator rotates output signals
}

__constants.enums.CombinatorState = {
    PowerOff = 1,       -- No power, combinator will not work
    Working = 2,        -- Combinator is working
    InputUpdated = 3,   -- Auxiliary state, indicates that input was changed
    SettingsUpdated = 4 -- Auxiliary state, indicates that mod settings was changed
}

return __constants
