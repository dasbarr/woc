----------------------------------
-- Requires --
----------------------------------

local __constants = require("utils.constants")

----------------------------------
-- Settings --
----------------------------------

data:extend({
    {
        type = "int-setting",
        name = __constants.names.outputUpdateIntervalSettingName,
        setting_type = "runtime-global",
        default_value = __constants.settings.outputUpdateInterval,
        minimum_value = 1,
        maximum_value = 300,
        order = "a"
    },
    {
        type = "int-setting",
        name = __constants.names.inputCheckIntervalSettingName,
        setting_type = "runtime-global",
        default_value = __constants.settings.inputCheckInterval,
        minimum_value = 1,
        maximum_value = 300,
        order = "b"
    },
    {
        type = "int-setting",
        name = __constants.names.maxNumOutputSignalsSettingName,
        setting_type = "runtime-global",
        default_value = __constants.settings.maxNumOutputSignals,
        minimum_value = 1,
        maximum_value = 6,
        order = "c"
    },
    {
        type = "bool-setting",
        name = __constants.names.preserveSignalCountSettingName,
        setting_type = "runtime-global",
        default_value = __constants.settings.preserveSignalCount,
        order = "d"
    },
    {
        type = "bool-setting",
        name = __constants.names.inputOutputIconsAllowedSettingName,
        setting_type = "runtime-global",
        default_value = __constants.settings.inputOutputIconsAllowed,
        order = "e"
    }
})
