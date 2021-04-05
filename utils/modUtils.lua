local __modUtils = {}

----------------------------------
-- Requires --
----------------------------------

local __constants = require("utils.constants")

----------------------------------
-- Port-related functions --
----------------------------------

-- Creates a new port (input or output).
-- @param combinatorBaseEntity Base entity of a combinator.
-- @param portName Port name (input or output).
-- @return Created port.
__modUtils.CreatePort = function(combinatorBaseEntity, portName)
    port = combinatorBaseEntity.surface.create_entity {
        name = portName,
        position = combinatorBaseEntity.position,
        force = combinatorBaseEntity.force,
    }

    port.minable = false
    port.destructible = false
    port.operable = false
    
    return port
end

-- Sets proper positions for input and output ports.
-- @param combinatorEntry Entry with combinator data.
__modUtils.SetPortPositions = function(combinatorEntry)
    local baseEntityDirection = combinatorEntry.baseEntity.direction
    local baseEntityPosition = combinatorEntry.baseEntity.position
    
    local inputPortPosition, outputPortPosition
    if baseEntityDirection == defines.direction.west then
        inputPortPosition = { x = baseEntityPosition.x + 0.9, y = baseEntityPosition.y - 0.2 }
        outputPortPosition = { x = baseEntityPosition.x - 0.9, y = baseEntityPosition.y - 0.2 }
    elseif baseEntityDirection == defines.direction.east then
        inputPortPosition = { x = baseEntityPosition.x - 0.9, y = baseEntityPosition.y - 0.2 }
        outputPortPosition = { x = baseEntityPosition.x + 0.9, y = baseEntityPosition.y - 0.2 }
    elseif baseEntityDirection == defines.direction.north then
        inputPortPosition = { x = baseEntityPosition.x, y = baseEntityPosition.y + 0.8 }
        outputPortPosition = { x = baseEntityPosition.x, y = baseEntityPosition.y - 0.9 }
    elseif baseEntityDirection == defines.direction.south then
        inputPortPosition = { x = baseEntityPosition.x, y = baseEntityPosition.y - 0.8 }
        outputPortPosition = { x = baseEntityPosition.x, y = baseEntityPosition.y + 0.8 }
    end
    
    -- Teleport ports to new positions
    combinatorEntry.inputPort.teleport(inputPortPosition)
    combinatorEntry.outputPort.teleport(outputPortPosition)
    
    -- Set port directions (same for both ports)
    combinatorEntry.inputPort.direction = baseEntityDirection
    combinatorEntry.outputPort.direction = baseEntityDirection
end

----------------------------------
-- Signals --
----------------------------------

-- Sets provided signals as new current signals for a combinator.
-- @param combinatorEntry Entry with combinator data.
-- @param newSignals Array with new signals.
__modUtils.SetNewCurrentSignals = function(combinatorEntry, newSignals)
    if newSignals == nil then
        combinatorEntry.currentSignals = nil
    else
        -- Make deep copy of input signals
        local numSignals = #newSignals
        local signalsCopy = {}
        
        local signalIndex = 1
        for _, sourceSignal in pairs(newSignals) do
            signalsCopy[signalIndex] = { signal = sourceSignal.signal, count = sourceSignal.count }
            
            signalIndex = signalIndex + 1
        end
        
        combinatorEntry.currentSignals = signalsCopy
    end
end

-- Gets signals that will be used as source signals for combinator output.
-- @param combinatorEntry Entry with combinator data.
-- @return Array with source signals.
__modUtils.GetSourceSignalsForOutput = function(combinatorEntry)
    if inputCheckInterval == 1 then
        return combinatorEntry.inputPort.get_merged_signals(defines.circuit_connector_id.combinator_input)
    else
        return combinatorEntry.currentSignals
    end
end

----------------------------------
-- Output --
----------------------------------

-- Discards combinator output.
-- @param combinatorEntry Entry with combinator data.
__modUtils.RemoveOutput = function(combinatorEntry)
    combinatorEntry.outputPort.get_control_behavior().parameters = {}
    combinatorEntry.firstOutputSignalIndex = -1
    combinatorEntry.replacementSlotIndex = -1
    combinatorEntry.outputState = __constants.enums.OutputState.None
end

-- Sets combinator output.
-- @param outputPortControlBehaviour LuaControlBehaviour of combinator output port.
-- @param sourceSignals Signals that will be used as source for output.
-- @param firstSignalIndex Signal with that index will be first signal to show.
-- @param outputSignalsCount Number of signals that will be send to output.
__modUtils.SetCombinatorOutput = function(outputPortControlBehaviour, sourceSignals, firstSignalIndex, outputSignalsCount)
    local numSourceSignals = #sourceSignals
    
    local outputSignals = {}
    local currentSignalIndex = firstSignalIndex
    for i = 1, outputSignalsCount do
        local sourceSignal = sourceSignals[currentSignalIndex]
        
        outputSignals[i] = {
            signal = sourceSignal.signal,
            count = preserveSignalCount and sourceSignal.count or 1, -- If signal count is not preserved, use '1' as count
            index = i
        }
        
        -- Update current signal index
        currentSignalIndex = currentSignalIndex + 1
        if currentSignalIndex > numSourceSignals then
            currentSignalIndex = 1
        end
    end
    
    outputPortControlBehaviour.parameters = outputSignals
end

-- Rotates combinator output - moves output 'window', hides one of previously shown signals and shows a new one.
-- @param combinatorEntry Entry with combinator data.
-- @param maxNumOutputSignals Max number of output signals that combinator can show.
__modUtils.RotateOutput = function(combinatorEntry, maxNumOutputSignals)
    local signalsForOutput = __modUtils.GetSourceSignalsForOutput(combinatorEntry)
    local numSignalsForOutput = #signalsForOutput
    
    if preserveSignalCount then
        -- We need to update all output positions because count values for some output slots could be changed since the last rotate
        local nextFirstOutputSignalIndex = combinatorEntry.firstOutputSignalIndex + 1
        if nextFirstOutputSignalIndex > numSignalsForOutput then
            nextFirstOutputSignalIndex = 1
        end
        
        __modUtils.SetCombinatorOutput(combinatorEntry.outputPort.get_control_behavior(), signalsForOutput, nextFirstOutputSignalIndex, maxNumOutputSignals)
        
        combinatorEntry.firstOutputSignalIndex = nextFirstOutputSignalIndex
    else
        -- We don't bother with actual signal count, so just replace one signal with a new one instead of replacing all signals
        local nextSignalToShowIndex = combinatorEntry.firstOutputSignalIndex + maxNumOutputSignals
        if nextSignalToShowIndex > numSignalsForOutput then
            nextSignalToShowIndex = nextSignalToShowIndex - numSignalsForOutput
        end
        
        local signalToSet = signalsForOutput[nextSignalToShowIndex]
        combinatorEntry.outputPort.get_control_behavior().set_signal(combinatorEntry.replacementSlotIndex, { signal = signalToSet.signal, count = 1})
        
        -- Update firstOutputSignalIndex
        combinatorEntry.firstOutputSignalIndex = combinatorEntry.firstOutputSignalIndex + 1
        if combinatorEntry.firstOutputSignalIndex > numSignalsForOutput then
            combinatorEntry.firstOutputSignalIndex = 1
        end
        
        -- Update next replacementSlotIndex
        combinatorEntry.replacementSlotIndex = combinatorEntry.replacementSlotIndex + 1
        if combinatorEntry.replacementSlotIndex > maxNumOutputSignals then
            combinatorEntry.replacementSlotIndex = 1
        end
    end
end

----------------------------------
-- Icons --
----------------------------------

-- Discards work icon.
-- @param combinatorEntry Entry with combinator data.
__modUtils.RemoveWorkIcon = function(combinatorEntry)
    local workIconData = combinatorEntry.workIcon
    if workIconData.shown then
        rendering.destroy(workIconData.spriteId)
        workIconData.spriteId = nil
        workIconData.shown = false
    end
end

-- Updates work icon.
-- @param combinatorEntry Entry with combinator data.
__modUtils.UpdateWorkIcon = function(combinatorEntry)
    -- Remove previous icon
    __modUtils.RemoveWorkIcon(combinatorEntry)
    
    -- Show new icon (if necessary)
    local iconShowData
    local combinatorState = combinatorEntry.combinatorState
    if combinatorState == __constants.enums.CombinatorState.Working then
        local baseEntityDirection = combinatorEntry.baseEntity.direction
        local combinatorOutputState = combinatorEntry.outputState
        
        if combinatorOutputState == __constants.enums.OutputState.Forward then
            iconShowData = {}
            
            if baseEntityDirection == defines.direction.west then
                iconShowData.sprite = __constants.names.forwardHorizontalIconSprite
                iconShowData.orientation = 0.5
                iconShowData.targetOffset = { 0.0, -0.6 }
            elseif baseEntityDirection == defines.direction.east then
                iconShowData.sprite = __constants.names.forwardHorizontalIconSprite
                iconShowData.orientation = 0
                iconShowData.targetOffset = { 0.0, -0.31 }
            elseif baseEntityDirection == defines.direction.north then
                iconShowData.sprite = __constants.names.forwardVerticalIconSprite
                iconShowData.orientation = 0
                iconShowData.targetOffset = { 0.0, 0.0 }
            elseif baseEntityDirection == defines.direction.south then
                iconShowData.sprite = __constants.names.forwardVerticalIconSprite
                iconShowData.orientation = 0.5
                iconShowData.targetOffset = { 0.0, -0.3 }
            end
        elseif combinatorOutputState == __constants.enums.OutputState.Rotation then
            iconShowData = {}
            
            iconShowData.sprite = __constants.names.rotationIconSprite
            iconShowData.orientation = 0
            
            if baseEntityDirection == defines.direction.west or baseEntityDirection == defines.direction.east then
                iconShowData.targetOffset = { 0.0, -0.31 }
            else -- if baseEntityDirection is north or south
                iconShowData.targetOffset = { 0.0, 0.0 }
            end
        end
    end
    if iconShowData then
        local workIconData = combinatorEntry.workIcon
        workIconData.spriteId = rendering.draw_sprite { 
            sprite = iconShowData.sprite,
            orientation = iconShowData.orientation,
            render_layer = "entity-info-icon",
            target = combinatorEntry.baseEntity,
            target_offset = iconShowData.targetOffset,
            surface = combinatorEntry.baseEntity.surface
        }
        workIconData.shown = true
    end
end

-- Updates input-output icons (yellow triangles).
-- @param combinatorEntry Entry with combinator data.
-- @param iconsAllowed If true, input-output icons will be shown.
__modUtils.UpdateInputOutputIcons = function(combinatorEntry, iconsAllowed)
    local iconsData = combinatorEntry.inputOutputIcons
    
    if iconsAllowed then
        if not iconsData.shown then
            -- Show icons
            local spriteData = { 
                sprite = "utility/indication_arrow",
                render_layer = "wires-above",
                target = combinatorEntry.baseEntity,
                surface = combinatorEntry.baseEntity.surface,
                only_in_alt_mode = true,
                x_scale = 0.75,
                y_scale = 0.75
            }
            
            -- Just draw, position and orientation will be set later
            iconsData.icon1SpriteId = rendering.draw_sprite(spriteData)
            iconsData.icon2SpriteId = rendering.draw_sprite(spriteData)
            
            iconsData.shown = true
        end
        
        -- Set proper icon positions and orientation
        local baseEntityDirection = combinatorEntry.baseEntity.direction
        local iconOrientation, icon1TargetOffset, icon2TargetOffset
        
        if baseEntityDirection == defines.direction.west then
            iconOrientation = 0.75
            icon1TargetOffset = { -0.75, 0.0 }
            icon2TargetOffset = { 0.75, 0.0 }
        elseif baseEntityDirection == defines.direction.east then
            iconOrientation = 0.25
            icon1TargetOffset = { -0.75, 0.0 }
            icon2TargetOffset = { 0.75, 0.0 }
        elseif baseEntityDirection == defines.direction.north then
            iconOrientation = 0.0
            icon1TargetOffset = { 0.0, -0.75 }
            icon2TargetOffset = { 0.0, 0.75 }
        elseif baseEntityDirection == defines.direction.south then
            iconOrientation = 0.5
            icon1TargetOffset = { 0.0, -0.75 }
            icon2TargetOffset = { 0.0, 0.75 }
        end
        
        rendering.set_target(iconsData.icon1SpriteId, combinatorEntry.baseEntity, icon1TargetOffset)
        rendering.set_orientation(iconsData.icon1SpriteId, iconOrientation)
        
        rendering.set_target(iconsData.icon2SpriteId, combinatorEntry.baseEntity, icon2TargetOffset)
        rendering.set_orientation(iconsData.icon2SpriteId, iconOrientation)
    else
        if iconsData.shown then
            -- Remove unnecessary icons
            rendering.destroy(iconsData.icon1SpriteId)
            iconsData.icon1SpriteId = nil
            rendering.destroy(iconsData.icon2SpriteId)
            iconsData.icon2SpriteId = nil
            iconsData.shown = false
        end
    end
end

return __modUtils
