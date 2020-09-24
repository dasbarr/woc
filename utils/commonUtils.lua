local __commonUtils = {}

----------------------------------
-- Signals --
----------------------------------

-- Determines if provided signals are the same.
-- @param signal1 1st signal.
-- @param signal2 2nd signal.
-- @return True if signals are the same, false otherwise.
__commonUtils.SameSignal = function(signal1, signal2)
    if signal1 == signal2 then
        return true
    end

    if signal1.type == signal2.type and signal1.name == signal2.name then
        return true
    end

    return false
end

-- Determines if provided arrays have equal signals.
-- @param signals1 1st array with signals.
-- @param signals2 2nd array with signals.
-- @return True if signals are the same, false otherwise.
__commonUtils.HasSameSignals = function(signals1, signals2)
    if signals1 == nil and signals2 == nil then
        return true
    end

    if (signals1 == nil and signals2 ~= nil) or (signals1 ~= nil and signals2 == nil) then
        return false
    end

    local numSignals = #signals1
    if numSignals ~= #signals2 then
        return false
    end
    
    -- It's assumed that order of signals is the same
    for i = 1, numSignals do
        local signal1 = signals1[i].signal or signals1[i]
        local signal2 = signals2[i].signal or signals2[i]
        
        if not __commonUtils.SameSignal(signal1, signal2) then
            return false
        end
    end

    return true
end

-- Updates signal counts in destination array using data from source array.
-- Note that it's assumed that signalsCountSource and signalsCountDest has the same signals in the same order.
-- @param signalsCountSource Source array with signals.
-- @param signalsCountDest Destination array with signals.
__commonUtils.UpdateSignalCounts = function(signalsCountSource, signalsCountDest)
    local numSignals = signalsCountSource and #signalsCountSource or 0
    
    for i = 1, numSignals do
        signalsCountDest[i].count = signalsCountSource[i].count
    end
end

return __commonUtils
