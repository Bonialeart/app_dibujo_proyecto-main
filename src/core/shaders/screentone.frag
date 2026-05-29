#version 330 core
in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uSource;
uniform float u_dotSize;      // Size of the screentone dots (frequency)
uniform float u_angle;        // Angle of rotation (in radians)
uniform float u_contrast;     // Sharpness transition of the dots

vec2 rotate(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

void main() {
    vec4 srcColor = texture(uSource, vTexCoord);
    if (srcColor.a < 0.005) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Convert source pixel to luminance
    float luma = dot(srcColor.rgb, vec3(0.299, 0.587, 0.114));
    
    // Rotate canvas pixel coordinates to align with screentone angle
    vec2 rotatedUV = rotate(gl_FragCoord.xy, u_angle);
    
    // Generate grid periodic pattern
    vec2 gridPos = fract(rotatedUV / u_dotSize) - vec2(0.5);
    float distToCenter = length(gridPos);
    
    // Circular dot radius is proportional to darkness (1.0 - luma)
    float targetRadius = 0.5 * (1.0 - luma);
    
    // Antialiased threshold to prevent jagged aliasing
    float transitionWidth = 0.05 + 0.45 * (1.0 - u_contrast);
    float dotAlpha = smoothstep(targetRadius + transitionWidth, targetRadius - transitionWidth, distToCenter);
    
    // Draw monochromatic black screentone dots retaining original layer transparency
    fragColor = vec4(vec3(0.0), dotAlpha * srcColor.a);
}
