-- Snow Brush Script
-- Simulates falling snowflakes with random rotation and size flutter.

local brush = {}

function brush.onDab(context)
    -- Random rotation (360 degrees in radians)
    local rotationOffset = math.random() * math.pi * 2
    
    -- Sublte size flutter based on distance (harmonic motion)
    local sizeFlutter = 0.9 + math.sin(context.distance * 0.1) * 0.2
    
    -- Opacity slightly varied by pressure
    local opacityMult = 0.5 + (context.pressure * 0.5)

    return {
        sizeMultiplier = sizeFlutter,
        rotationOffset = rotationOffset,
        opacityMultiplier = opacityMult
    }
end

return brush
