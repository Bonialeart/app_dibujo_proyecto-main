// ArtFlow Studio — Liquify Displacement Shader
// Applies a displacement map to deform a source texture in real-time.
//
// Uniforms:
//   uSource       – original layer texture (RGBA)
//   uDisplacement – RG32F displacement map (dx in R, dy in G, normalized)
//   uScreenSize   – viewport size for UV calculation
//   uCanvasSize   – canvas pixel dimensions
//   uOpacity      – preview opacity

#version 120

varying vec2 vTexCoord;

uniform sampler2D uSource;
uniform sampler2D uDisplacement;
uniform vec2      uCanvasSize;
uniform float     uOpacity;

void main() {
    // Read displacement (stored as normalized floats in RG channels)
    // Displacement is encoded as: actual_offset = (texel.rg - 0.5) * 2.0 * maxDisp
    vec4 disp = texture2D(uDisplacement, vTexCoord);

    // Decode: range [-1,1] * maxRange  →  pixel offset / canvasSize → UV offset
    float maxRange = 500.0; // max pixel displacement range
    vec2 offset;
    offset.x = (disp.r - 0.5) * 2.0 * maxRange / uCanvasSize.x;
    offset.y = (disp.g - 0.5) * 2.0 * maxRange / uCanvasSize.y;

    // Sample source at displaced UV
    vec2 sampleUV = vTexCoord + offset;

    // Clamp to canvas bounds
    sampleUV = clamp(sampleUV, vec2(0.0), vec2(1.0));

    vec4 color = texture2D(uSource, sampleUV);

    gl_FragColor = color * uOpacity;
}
