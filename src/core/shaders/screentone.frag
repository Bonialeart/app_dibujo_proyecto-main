#version 330 core
in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uSource;
uniform float u_dotSize;      // Size of the screentone dots (frequency)
uniform float u_angle;        // Angle of rotation (in radians)
uniform float u_contrast;     // Sharpness transition of the dots
uniform int u_patternType;    // 0 = Circle, 1 = Line, 2 = Noise

vec2 rotate(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec4 srcColor = texture(uSource, vTexCoord);
    if (srcColor.a < 0.005) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Convert source pixel to luminance
    float luma = dot(srcColor.rgb, vec3(0.299, 0.587, 0.114));
    
    float dotAlpha = 0.0;
    
    if (u_patternType == 0) {
        // Círculos (Circles)
        vec2 rotatedUV = rotate(gl_FragCoord.xy, u_angle);
        vec2 gridPos = fract(rotatedUV / u_dotSize) - vec2(0.5);
        float distToCenter = length(gridPos);
        float targetRadius = 0.5 * (1.0 - luma);
        float transitionWidth = 0.05 + 0.45 * (1.0 - u_contrast);
        
        // Standard compliant edge0 < edge1 to prevent undefined driver behavior on AMD/Intel cards
        float edge0 = targetRadius - transitionWidth;
        float edge1 = targetRadius + transitionWidth;
        dotAlpha = 1.0 - smoothstep(edge0, edge1, distToCenter);
    } else if (u_patternType == 1) {
        // Líneas (Lines)
        vec2 rotatedUV = rotate(gl_FragCoord.xy, u_angle);
        vec2 gridPos = fract(rotatedUV / u_dotSize) - vec2(0.5);
        float distToLine = abs(gridPos.x);
        float targetWidth = 0.5 * (1.0 - luma);
        float transitionWidth = 0.05 + 0.45 * (1.0 - u_contrast);
        
        // Standard compliant edge0 < edge1 to prevent undefined driver behavior on AMD/Intel cards
        float edge0 = targetWidth - transitionWidth;
        float edge1 = targetWidth + transitionWidth;
        dotAlpha = 1.0 - smoothstep(edge0, edge1, distToLine);
    } else if (u_patternType == 2) {
        // Ruido / Dither (Noise)
        float grainSize = max(1.0, floor(u_dotSize * 0.25));
        float noiseVal = rand(floor(gl_FragCoord.xy / grainSize));
        dotAlpha = noiseVal > luma ? 1.0 : 0.0;
    }
    
    // Draw monochromatic black screentone dots retaining original layer transparency
    fragColor = vec4(vec3(0.0), dotAlpha * srcColor.a);
}
