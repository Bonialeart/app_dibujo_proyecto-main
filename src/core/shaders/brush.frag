#version 330 core

in vec2 TexCoords;
out vec4 FragColor;

// === Core Uniforms ===
uniform vec4 color;
uniform float pressure;
uniform float hardness;
uniform float flow;
uniform int brushType;

// === Brush Tip (Shape Texture) — Local UV Mapping ===
uniform sampler2D tipTexture;
uniform int uHasTip;           // 1 = custom tip, 0 = procedural round

// === Grain (Paper Texture) — Global Canvas Mapping ===
uniform sampler2D grainTexture;
uniform int uHasGrain;         // 1 = grain active
uniform float grainScale;
uniform float grainIntensity;

// === Wet Mix Engine ===
uniform sampler2D canvasTexture;  // Ping-pong buffer (existing paint on canvas)
uniform float wetness;            // 0 = dry, 1 = fully wet (blends with canvas)
uniform float dilution;           // Water dilution (thins opacity)
uniform float smudge;             // Pull amount (picks up canvas color)
uniform vec2 canvasSize;          // For screen-space UV

// === Dab Positioning (for global grain mapping) ===
uniform vec2 uDabPos;            // Global coordinates of dab center
uniform float uDabSize;          // Current brush diameter in pixels

// === Rotation ===
uniform float tipRotation;       // Brush tip rotation in radians

void main() {
    // === 1. SHAPE ALPHA (Brush Tip) ===
    float shapeAlpha = 1.0;

    // Rotate UV for tip if needed
    vec2 tipUV = TexCoords;
    if (abs(tipRotation) > 0.001) {
        vec2 center = vec2(0.5);
        vec2 d = tipUV - center;
        float cs = cos(tipRotation);
        float sn = sin(tipRotation);
        tipUV = center + vec2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
    }

    if (uHasTip == 1) {
        // CUSTOM BRUSH TIP — sample the tip texture in local UV space
        // If rotated UV goes out of bounds, alpha = 0
        if (tipUV.x < 0.0 || tipUV.x > 1.0 || tipUV.y < 0.0 || tipUV.y > 1.0) {
            shapeAlpha = 0.0;
        } else {
            vec4 tipSample = texture(tipTexture, tipUV);
            // Use luminance as alpha mask (grayscale tip textures)
            shapeAlpha = dot(tipSample.rgb, vec3(0.299, 0.587, 0.114));
            // Apply tip's own alpha channel too
            shapeAlpha *= tipSample.a;
        }
    } else {
        // PROCEDURAL ROUND TIP — smooth circle with hardness falloff
        float dist = distance(TexCoords, vec2(0.5));

        // Smooth anti-aliasing: feather increases as hardness decreases
        float feather = (1.0 - hardness) * 0.45 + 0.02;
        shapeAlpha = 1.0 - smoothstep(0.5 - feather, 0.5, dist);
    }

    // Early discard for fully transparent fragments
    if (shapeAlpha < 0.004) discard;

    // === 2. GRAIN MODULATION (Paper Texture) ===
    float grainFactor = 1.0;

    if (uHasGrain == 1 && grainIntensity > 0.001) {
        // GLOBAL CANVAS MAPPING — grain stays fixed to the paper position
        vec2 globalCoord = ((TexCoords - 0.5) * uDabSize + uDabPos) / (5.0 * grainScale);
        vec4 grainSample = texture(grainTexture, globalCoord);

        // Extract grain value (handles both grayscale and color textures)
        float grainVal = max(grainSample.a, dot(grainSample.rgb, vec3(0.299, 0.587, 0.114)));

        // Multiplicative blend controlled by intensity
        grainFactor = mix(1.0, grainVal, grainIntensity);
    }

    // === 3. FLOW & PRESSURE COMBINATION ===
    float effectiveFlow = flow * pressure;
    float baseAlpha = color.a * shapeAlpha * grainFactor * effectiveFlow;

    // Dilution reduces pigment density (makes color more transparent)
    baseAlpha *= (1.0 - dilution * 0.7);

    // === 4. WET MIX ENGINE ===
    vec3 finalRGB = color.rgb;

    if ((wetness > 0.01 || smudge > 0.01) && canvasSize.x > 1.0) {
        // Sample the existing canvas at this fragment's screen position
        // Convert dab-local UV to screen UV
        vec2 screenPos = ((TexCoords - 0.5) * uDabSize + uDabPos) / canvasSize;
        screenPos.y = 1.0 - screenPos.y; // Flip Y for FBO
        vec4 canvasColor = texture(canvasTexture, screenPos);

        // Unpremultiply canvas color for mixing
        vec3 canvasRGB = canvasColor.a > 0.001
            ? canvasColor.rgb / canvasColor.a
            : vec3(1.0);
        float canvasA = canvasColor.a;

        // SMUDGE: Pull canvas color into the brush
        if (smudge > 0.01 && canvasA > 0.01) {
            finalRGB = mix(finalRGB, canvasRGB, smudge * canvasA);
        }

        // WETNESS: Wet brushes blend more gently with underlying paint
        // Simulate paint mixing by modulating opacity based on what's underneath
        if (wetness > 0.01 && canvasA > 0.01) {
            // Darker pigment wins slightly (subtractive-ish mixing)
            float brushLum = dot(finalRGB, vec3(0.299, 0.587, 0.114));
            float canvasLum = dot(canvasRGB, vec3(0.299, 0.587, 0.114));

            // Mix colors based on wetness
            float mixAmount = wetness * 0.5 * canvasA;
            finalRGB = mix(finalRGB, canvasRGB, mixAmount);

            // Wet paint darkens slightly at edges (pigment pooling)
            float edgeDist = abs(shapeAlpha - 0.5) * 2.0;
            float pooling = wetness * 0.15 * edgeDist;
            finalRGB *= (1.0 - pooling);
        }
    }

    // === 5. FINAL OUTPUT (Premultiplied Alpha) ===
    float finalAlpha = clamp(baseAlpha, 0.0, 1.0);

    // Premultiplied output
    FragColor = vec4(finalRGB * finalAlpha, finalAlpha);
}
