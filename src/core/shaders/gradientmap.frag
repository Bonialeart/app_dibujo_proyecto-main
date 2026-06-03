#version 330 core
in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uSource;

// Dynamic Stops
uniform int uStopCount;
uniform float uStopPositions[16];
uniform vec3 uStopColors[16];

// Coordinates
uniform int uUseCoords; // 0 = global, 1 = linear, 2 = radial
uniform vec2 uStart;
uniform vec2 uEnd;
uniform vec2 uCanvasSize;

vec3 getDynamicGradientColor(float t) {
    if (uStopCount <= 0) return vec3(t);
    if (uStopCount == 1) return uStopColors[0];
    
    float clampT = clamp(t, uStopPositions[0], uStopPositions[uStopCount - 1]);
    
    if (clampT <= uStopPositions[0]) return uStopColors[0];
    
    // Constant-bounded loop for 100% compiler compatibility
    for (int i = 0; i < 15; i++) {
        if (i >= uStopCount - 1) {
            break;
        }
        if (clampT >= uStopPositions[i] && clampT <= uStopPositions[i+1]) {
            float dist = uStopPositions[i+1] - uStopPositions[i];
            float factor = (dist > 0.0) ? (clampT - uStopPositions[i]) / dist : 0.0;
            return mix(uStopColors[i], uStopColors[i+1], factor);
        }
    }
    return uStopColors[uStopCount - 1];
}

void main() {
    vec4 srcColor = texture(uSource, vTexCoord);
    if (srcColor.a < 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    
    vec3 rgb = srcColor.rgb / srcColor.a;
    float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
    luma = clamp(luma, 0.0, 1.0);
    
    vec3 mappedColor = getDynamicGradientColor(luma);
    
    // Apply coordinates blend factor
    float blendFactor = 1.0;
    if (uUseCoords != 0) {
        vec2 pixelPos;
        pixelPos.x = vTexCoord.x * uCanvasSize.x;
        pixelPos.y = (1.0 - vTexCoord.y) * uCanvasSize.y;
        
        if (uUseCoords == 1) { // Linear transition along uStart -> uEnd
            vec2 dir = uEnd - uStart;
            float lenSq = dot(dir, dir);
            float t = 0.0;
            if (lenSq > 0.0) {
                t = dot(pixelPos - uStart, dir) / lenSq;
            }
            blendFactor = 1.0 - clamp(t, 0.0, 1.0);
        } else if (uUseCoords == 2) { // Radial transition from uStart with radius |uEnd - uStart|
            float radius = length(uEnd - uStart);
            float dist = length(pixelPos - uStart);
            float t = (radius > 0.0) ? dist / radius : 0.0;
            blendFactor = 1.0 - clamp(t, 0.0, 1.0);
        }
    }
    
    // Interpolate original and mapped color based on the blend factor
    vec3 finalRGB = mix(rgb, mappedColor, blendFactor);
    
    fragColor = vec4(finalRGB * srcColor.a, srcColor.a);
}
