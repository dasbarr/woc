----------------------------------
-- Requires --
----------------------------------

local __constants = require("utils.constants")
local __commonUtils = require("utils.commonUtils")
local __modUtils = require("utils.modUtils")

----------------------------------
-- Settings --
----------------------------------

local inputCheckInterval = __constants.settings.inputCheckInterval
local outputUpdateInterval = __constants.settings.outputUpdateInterval
local maxNumOutputSignals = __constants.settings.maxNumOutputSignals
local preserveSignalCount = __constants.settings.preserveSignalCount
local inputOutputIconsAllowed = __constants.settings.inputOutputIconsAllowed

----------------------------------
-- Local variables --
----------------------------------

local energyConsumptionInterval = __constants.energyConsumptionInterval
-- Energy drain for a period equal to energyConsumptionInterval 
local energyDrain = __constants.energyUsageKW * 1000 * (energyConsumptionInterval / 60)

-- Contains functions that perform combinator state transitions
local __combinatorStateTransitions = {}

----------------------------------
-- Local functions --
----------------------------------

-- Creates data entry for a new combinator, inits a combinator.
-- @param combinatorBaseEntity Combinator base entity.
-- @return Entry with combinator data.
local function CreateCombinatorEntry(combinatorBaseEntity)
    local inputPort, outputPort
    
    -- Handle ghost ports (blueprinting support)
    local ghostSearchArea
    local baseEntityPosition, baseEntityDirection = combinatorBaseEntity.position, combinatorBaseEntity.direction
    if baseEntityDirection == defines.direction.west or baseEntityDirection == defines.direction.east then
        ghostSearchArea = {
            { baseEntityPosition.x - 0.951, baseEntityPosition.y - 0.211 },
            { baseEntityPosition.x + 0.951, baseEntityPosition.y + 0.211 }
        }
    elseif baseEntityDirection == defines.direction.north or baseEntityDirection == defines.direction.south then
        ghostSearchArea = {
            { baseEntityPosition.x - 0.211, baseEntityPosition.y - 0.951 },
            { baseEntityPosition.x + 0.211, baseEntityPosition.y + 0.951 }
        }
    end
    if ghostSearchArea then
        -- Revive func returns as 1st parameter info that we don't need. That variable will be used to store that info
        local unused
        
        local possibleGhosts = combinatorBaseEntity.surface.find_entities(ghostSearchArea)
        for _, possibleGhost in pairs(possibleGhosts) do
            if possibleGhost.name == "entity-ghost" then
                -- Revive ghost ports
                if possibleGhost.ghost_name == __constants.names.inputPortName then
                    unused, inputPort = possibleGhost.revive()
                elseif possibleGhost.ghost_name == __constants.names.outputPortName then
                    unused, outputPort = possibleGhost.revive()
                end
            elseif possibleGhost.name == __constants.names.inputPortName then
                -- Input port already exists and it is not a ghost, just use it
                inputPort = possibleGhost
            elseif possibleGhost.name == __constants.names.outputPortName then
                -- Output port already exists and it is not a ghost, just use it
                outputPort = possibleGhost
            end
        end
    end
    
    -- Create ports if they weren't revived
    if inputPort == nil then
        inputPort = __modUtils.CreatePort(combinatorBaseEntity, __constants.names.inputPortName)
    end
    if outputPort == nil then
        outputPort = __modUtils.CreatePort(combinatorBaseEntity, __constants.names.outputPortName)
    end

    -- Combine all combinator data to that 'entry' table
    local combinatorEntry = {
        baseEntity = combinatorBaseEntity,

        inputPort = inputPort,
        outputPort = outputPort,

        -- Current input signals (saved value since last input check)
        currentSignals = nil,
        -- Signal with that index will be first signal to show. -1 means invalid index.
        firstOutputSignalIndex = -1,
        -- If signal count is not preserved in output, an output optimization can be made - instead of updating the whole output,
        -- only one output slot will be replaced. -1 means invalid index.
        replacementSlotIndex = -1,
        
        -- Current combinator state. Combinator behaves differently in different states.
        combinatorState = __constants.enums.CombinatorState.PowerOff,
        -- Combinator output state (combinator provides different output based on output state)
        outputState = __constants.enums.OutputState.None,
        
        -- Work icon, shown on combinator display when combinator is working
        workIcon = {
            spriteId = nil,
            shown = false
        },
        
        -- Input-output icons, shown near ports, highlighting data flow
        inputOutputIcons = {
            icon1SpriteId = nil,
            icon2SpriteId = nil,
            shown = false
        }
    }
    
    -- Set initial port positions
    __modUtils.SetPortPositions(combinatorEntry)
    
    -- Set input-output icons 
    __modUtils.UpdateInputOutputIcons(combinatorEntry, inputOutputIconsAllowed)

    return combinatorEntry
end

-- Applies global mod settings.
local function ApplySettings()
    inputCheckInterval = settings.global[__constants.names.inputCheckIntervalSettingName].value
    outputUpdateInterval = settings.global[__constants.names.outputUpdateIntervalSettingName].value
    maxNumOutputSignals = settings.global[__constants.names.maxNumOutputSignalsSettingName].value
    preserveSignalCount = settings.global[__constants.names.preserveSignalCountSettingName].value
    inputOutputIconsAllowed = settings.global[__constants.names.inputOutputIconsAllowedSettingName].value
end

----------------------------------
-- Combinator state transitions --
----------------------------------

-- Transition to PowerOff state.
-- @param Entry with combinator data.
__combinatorStateTransitions[__constants.enums.CombinatorState.PowerOff] = function(combinatorEntry)
    -- Set new combinator state
    combinatorEntry.combinatorState = __constants.enums.CombinatorState.PowerOff
    
    -- Remove output
    __modUtils.RemoveOutput(combinatorEntry)
    __modUtils.UpdateWorkIcon(combinatorEntry)
end

-- Transition to Working state.
-- @param Entry with combinator data.
__combinatorStateTransitions[__constants.enums.CombinatorState.Working] = function(combinatorEntry)
    -- Set new combinator state
    combinatorEntry.combinatorState = __constants.enums.CombinatorState.Working
    
    local signalsForOutput = __modUtils.GetSourceSignalsForOutput(combinatorEntry)
    local numSignalsForOutput = signalsForOutput and #signalsForOutput or 0
    
    local outputPortControlBehaviour = combinatorEntry.outputPort.get_control_behavior()
    if numSignalsForOutput == 0 then
        -- No output
        __modUtils.RemoveOutput(combinatorEntry)
    elseif numSignalsForOutput <= maxNumOutputSignals then
        -- Forward input to output, reset signal rotation parameters
        __modUtils.SetCombinatorOutput(outputPortControlBehaviour, signalsForOutput, 1, numSignalsForOutput)
        combinatorEntry.firstOutputSignalIndex = -1
        combinatorEntry.replacementSlotIndex = -1

        combinatorEntry.outputState = __constants.enums.OutputState.Forward
    else
        -- Forward some first signals to output, make preparation for signal rotation
        __modUtils.SetCombinatorOutput(outputPortControlBehaviour, signalsForOutput, 1, maxNumOutputSignals)
        combinatorEntry.firstOutputSignalIndex = 1
        combinatorEntry.replacementSlotIndex = 1

        combinatorEntry.outputState = __constants.enums.OutputState.Rotation
    end
    
    -- Update icon
    __modUtils.UpdateWorkIcon(combinatorEntry)
end

-- Transition to InputUpdated state.
-- @param Entry with combinator data.
__combinatorStateTransitions[__constants.enums.CombinatorState.InputUpdated] = function(combinatorEntry)
    -- InputUpdated is an intermediate state used to 'reset' Working state on input update, so go to the Working state
    __combinatorStateTransitions[__constants.enums.CombinatorState.Working](combinatorEntry)
end

-- Transition to SettingsUpdated state.
-- @param Entry with combinator data.
__combinatorStateTransitions[__constants.enums.CombinatorState.SettingsUpdated] = function(combinatorEntry)
    -- SettingsUpdated is an intermediate state used to 'reset' Working state on settings update, so go to the Working state
    __combinatorStateTransitions[__constants.enums.CombinatorState.Working](combinatorEntry)
end

----------------------------------
-- Event handlers --
----------------------------------

-- Handles new entity built event.
-- @param event Event.
local function OnEntityBuilt(event)
    local builtEntity = event.created_entity
    if not builtEntity or not builtEntity.valid then
        return
    end
    
    if builtEntity.name == "entity-ghost" then
        if builtEntity.ghost_name == __constants.names.inputPortName or builtEntity.ghost_name == __constants.names.outputPortName then
            -- If there is an already existed port near current port position, remove current port as duplicate
            -- (Unnecessary ghosts can be created by multiple clicks with blueprints, because they are placed off-grid)
            local currentPortPosition = builtEntity.position
            local alreadyExistedPortSearchArea = {
                { currentPortPosition.x - 0.41, currentPortPosition.y - 0.41 },
                { currentPortPosition.x + 0.41, currentPortPosition.y + 0.41 }
            }
            
            local possibleAlreadyExistedPorts = builtEntity.surface.find_entities(alreadyExistedPortSearchArea)
            -- Save unit number locally for the case when builtEntity will be destroyed, but there are some loop iterations left
            local builtEntityUnitNumber = builtEntity.unit_number
            local entityAlreadyDestroyed = false
            for _, possibleAlreadyExistedPort in pairs(possibleAlreadyExistedPorts) do
                -- It's not necessary to check entities if builtEntity was already destroyed
                if not entityAlreadyDestroyed then
                    local destroyNeeded = false
                    if possibleAlreadyExistedPort.unit_number ~= builtEntityUnitNumber then
                        if possibleAlreadyExistedPort.name == "entity-ghost" and (possibleAlreadyExistedPort.ghost_name == __constants.names.inputPortName or possibleAlreadyExistedPort.ghost_name == __constants.names.outputPortName) then
                            -- Mark entity for destroy
                            destroyNeeded = true
                        elseif possibleAlreadyExistedPort.name == __constants.names.inputPortName or possibleAlreadyExistedPort.name == __constants.names.outputPortName then
                            -- Mark entity for destroy
                            destroyNeeded = true
                        end
                    end
                    
                    if destroyNeeded then
                        -- Remove unnecessary entity
                        builtEntity.destroy()
                        entityAlreadyDestroyed = true
                    end
                end
            end
        end
    elseif builtEntity.name == __constants.names.wocCombinatorName then
        -- Construct and add combinator entry to combinators list for update purposes
        local combinatorEntry = CreateCombinatorEntry(builtEntity)
        global.g_wocCombinators[builtEntity.unit_number] = combinatorEntry

        -- Set initial signals
        local inputSignals = combinatorEntry.inputPort.get_merged_signals(defines.circuit_connector_id.combinator_input)
        __modUtils.SetNewCurrentSignals(combinatorEntry, inputSignals)
        -- Don't update input now, it will be updated after 1st energy consumption
    end
end

-- Handles entity remove event.
-- @param event Event.
local function OnEntityRemoved(event)
    local removedEntity = event.entity
    if not removedEntity or not removedEntity.valid then
        return
    end

    if removedEntity.name == __constants.names.wocCombinatorName then
        local combinatorEntry = global.g_wocCombinators[removedEntity.unit_number]
        if combinatorEntry then
            -- Remove icons
            __modUtils.RemoveWorkIcon(combinatorEntry)
            local inputOutputIconsData = combinatorEntry.inputOutputIcons
            if inputOutputIconsData.shown then
                rendering.destroy(inputOutputIconsData.icon1SpriteId)
                rendering.destroy(inputOutputIconsData.icon2SpriteId)
            end
            
            -- Remove input port
            if combinatorEntry.inputPort then
                combinatorEntry.inputPort.destroy()
                combinatorEntry.inputPort = nil
            end

            -- Remove output port
            if combinatorEntry.outputPort then
                combinatorEntry.outputPort.destroy()
                combinatorEntry.outputPort = nil
            end

            combinatorEntry.baseEntity = nil
            combinatorEntry.currentSignals = nil

            global.g_wocCombinators[removedEntity.unit_number] = nil
        end
    end
end

-- Handles entity rotation event.
-- @param event Event.
local function OnEntityRotated(event)
    local rotatedEntity = event.entity
    if not rotatedEntity or not rotatedEntity.valid then
        return
    end
    
    if rotatedEntity.name == __constants.names.wocCombinatorName then
        local combinatorEntry = global.g_wocCombinators[rotatedEntity.unit_number]
        if combinatorEntry then
            -- Update port positions
            __modUtils.SetPortPositions(combinatorEntry)
            
            -- Update icons
            __modUtils.UpdateWorkIcon(combinatorEntry)
            __modUtils.UpdateInputOutputIcons(combinatorEntry, inputOutputIconsAllowed)
        end
    end
end

-- Handles on_tick event.
-- @param event Event.
local function OnTick(event)
    local tickCount = event.tick
    local energyConsumptionNeeded = tickCount % energyConsumptionInterval == 0
    local inputCheckNeeded = inputCheckInterval == 1 or tickCount % inputCheckInterval == 0
    local outputUpdateNeeded = tickCount % outputUpdateInterval == 0

    if energyConsumptionNeeded or inputCheckNeeded or outputUpdateNeeded then
        for _, combinatorEntry in pairs(global.g_wocCombinators) do
            if combinatorEntry.baseEntity and combinatorEntry.baseEntity.valid then
                local currentCombinatorState = combinatorEntry.combinatorState
                -- If not changed below, combinator state will be the same
                local newCombinatorState = combinatorEntry.combinatorState
                
                -- Consume enegry (if possible)
                if energyConsumptionNeeded then
                    local currentEnergy = combinatorEntry.baseEntity.energy
                    if currentEnergy >= energyDrain then
                        -- Drain energy
                        combinatorEntry.baseEntity.energy = currentEnergy - energyDrain
                        
                        if currentCombinatorState == __constants.enums.CombinatorState.PowerOff then
                            -- Enable combinator
                            newCombinatorState = __constants.enums.CombinatorState.Working
                        end
                    else
                        -- Not enough energy, switching off
                        newCombinatorState = __constants.enums.CombinatorState.PowerOff
                    end
                end
                
                -- Check input
                if inputCheckNeeded then
                    local inputSignals = combinatorEntry.inputPort.get_merged_signals(defines.circuit_connector_id.combinator_input)
                    if __commonUtils.HasSameSignals(inputSignals, combinatorEntry.currentSignals) then
                        -- Signals are the same, update signal counts (if necessary)
                        if inputCheckInterval ~= 1 and preserveSignalCount then
                            -- In that case output will use stored current signals as source, so update signal counts
                            __commonUtils.UpdateSignalCounts(inputSignals, combinatorEntry.currentSignals)
                        end
                    else
                        -- Signals are not the same, update current signals and change combinator state (if necessary)
                        __modUtils.SetNewCurrentSignals(combinatorEntry, inputSignals)
                        
                        if newCombinatorState == currentCombinatorState and currentCombinatorState == __constants.enums.CombinatorState.Working then
                            newCombinatorState = __constants.enums.CombinatorState.InputUpdated
                        end
                    end
                end
                
                -- Update combinator state
                if newCombinatorState ~= currentCombinatorState then
                    local changeStateFunc = __combinatorStateTransitions[newCombinatorState]
                    if changeStateFunc then
                        -- Change state
                        changeStateFunc(combinatorEntry)
                    else
                        -- State doesn't exist, but just set it directly to avoid endless loop
                        combinatorEntry.combinatorState = newCombinatorState
                    end
                else
                    -- rotate output if necessary
                    if outputUpdateNeeded and currentCombinatorState == __constants.enums.CombinatorState.Working and combinatorEntry.outputState == __constants.enums.OutputState.Rotation then
                        __modUtils.RotateOutput(combinatorEntry, maxNumOutputSignals)
                    end
                end
            end
        end
    end
end

-- Handles on_runtime_mod_setting_changed event.
-- @param event Event.
local function onRuntimeModSettingChanged(event)
    local maxNumOutputSignalsPrevValue = maxNumOutputSignals
    local preserveSignalCountPrevValue = preserveSignalCount
    local inputOutputIconsAllowedPrevValue = inputOutputIconsAllowed
    
    -- Apply new values
    ApplySettings()
    
    if maxNumOutputSignals ~= maxNumOutputSignalsPrevValue or preserveSignalCount ~= preserveSignalCountPrevValue or inputOutputIconsAllowed ~= inputOutputIconsAllowedPrevValue then
        -- Working combinators should be updated
        local changeStateFunc = __combinatorStateTransitions[__constants.enums.CombinatorState.SettingsUpdated]
        for _, combinatorEntry in pairs(global.g_wocCombinators) do
            if combinatorEntry.baseEntity and combinatorEntry.baseEntity.valid then
                if combinatorEntry.combinatorState == __constants.enums.CombinatorState.Working then
                    changeStateFunc(combinatorEntry)
                end
                
                __modUtils.UpdateInputOutputIcons(combinatorEntry, inputOutputIconsAllowed)
            end
        end
    end
end

----------------------------------
-- Event subscriptions --
----------------------------------

script.on_event({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, OnEntityBuilt)
script.on_event({ defines.events.on_entity_died, defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined }, OnEntityRemoved)
script.on_event(defines.events.on_player_rotated_entity, OnEntityRotated)
script.on_event(defines.events.on_tick, OnTick)
script.on_event(defines.events.on_runtime_mod_setting_changed, onRuntimeModSettingChanged)

script.on_init(function()
    -- Create global table for combinators if it doesn't exist (it will be used for combinator update)
    if global.g_wocCombinators == nil then
        global.g_wocCombinators = {}
    end
end)

script.on_load(function()
    ApplySettings()
end)
