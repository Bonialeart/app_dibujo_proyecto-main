-- Speedy Brush Script
-- This brush increases in size as you move faster and shifts color slightly.

local brush = {}

function brush.onDab(context)
    local v = context.velocity
    local pressure = context.pressure
    
    -- Increase size with velocity (v is approx 0 to 2000)
    local sizeMult = 1.0 + (v / 500.0)
    
    -- Slightly shift hue based on velocity
    local hueShift = (v / 2000.0) * 0.1
    
    -- Decrease opacity if moving REALLY fast
    local opacityMult = 1.0
    if v > 1000 then
        opacityMult = 1.0 - ((v - 1000) / 1000.0) * 0.5
    end

    return {
        sizeMultiplier = sizeMult,
        hueShift = hueShift,
        opacityMultiplier = opacityMult
    }
end

return brush
