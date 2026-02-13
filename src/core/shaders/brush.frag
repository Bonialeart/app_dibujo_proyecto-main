#version 330 core

in vec2 TexCoords;
out vec4 FragColor;

uniform vec4 color;
uniform float pressure;
uniform float hardness;
uniform int brushType;

uniform sampler2D brushTexture;
uniform int uHasTexture;
uniform float textureScale;
uniform float textureIntensity;
uniform vec2 uDabPos;    // Global coordinates of dab center
uniform float uDabSize;  // Current brush radius*2

void main() {
    float dist = distance(TexCoords, vec2(0.5));
    
    // SMOOTH ANTI-ALIASING
    // feather increases as hardness decreases. Min 0.02 for subpixel AA.
    float feather = (1.0 - hardness) * 0.45 + 0.02;
    float alpha = 1.0 - smoothstep(0.5 - feather, 0.5, dist);
    
    if (uHasTexture == 1) {
        // GLOBAL CANVAS MAPPING for textures
        // This makes the grain stay fixed to the paper, not the brush tip.
        vec2 globalCoord = ((TexCoords - 0.5) * uDabSize + uDabPos) / (5.0 * textureScale);
        vec4 texSample = texture(brushTexture, globalCoord);
        
        // Multiplicative intensity for the grain
        float grainVal = max(texSample.a, texSample.r);
        alpha *= mix(1.0, grainVal, textureIntensity);
    }

    float finalAlpha = color.a * alpha * pressure;
    
    // PREMULTIPLIED OUTPUT
    FragColor = vec4(color.rgb * finalAlpha, finalAlpha);
}
