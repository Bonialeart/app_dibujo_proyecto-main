-- Rain Brush Script
-- Ensures rain drops are aligned with the stroke and vary with speed.

local brush = {}

function brush.onDab(context)
    -- Align with stroke direction
    -- The context provides context.angle which is the stroke direction
    -- We can add a bit of jitter to the angle to make it less "perfect"
    local angleJitter = (math.random() - 0.5) * 0.1
    local rotationOffset = angleJitter
    
    -- Faster motion = thinner/longer look (simulated via opacity/size)
    local v = context.velocity
    local opacityMult = math.min(1.0, 0.3 + (v / 1000.0))
    local sizeMult = 0.8 + (context.pressure * 0.4)

    return {
        sizeMultiplier = sizeMult,
        rotationOffset = rotationOffset,
        opacityMultiplier = opacityMult
    }
end

return brush
