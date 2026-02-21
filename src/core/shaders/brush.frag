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

// === New Watercolor Uniforms ===
uniform float bleed;
uniform float granulation;
uniform float pigmentFlow;
uniform float staining;
uniform float separation;

uniform int bloomEnabled;
uniform float bloomIntensity;
uniform float bloomRadius;
uniform float bloomThreshold;

uniform int edgeDarkeningEnabled;
uniform float edgeDarkeningIntensity;
uniform float edgeDarkeningWidth;

uniform int textureRevealEnabled;
uniform float textureRevealIntensity;
uniform float textureRevealPressureInfluence;

// === Oil Paint Uniforms ===
uniform float mixing;
uniform float loading;
uniform float depletionRate;
uniform int dirtyMixing;
uniform float colorPickup;
uniform int blendOnly;
uniform int scrapeThrough;

uniform int impastoEnabled;
uniform float impastoDepth;
uniform float impastoShine;
uniform float impastoTextureStrength;
uniform float impastoEdgeBuildup;
uniform int impastoDirectionalRidges;
uniform float impastoSmoothing;
uniform int impastoPreserveExisting;

uniform int bristlesEnabled;
uniform int bristleCount;
uniform float bristleStiffness;
uniform float bristleClumping;
uniform float bristleFanSpread;
uniform float bristleIndividualVariation;
uniform int bristleDryBrushEffect;
uniform float bristleSoftness;
uniform float bristlePointTaper;

uniform float smudgeStrength;
uniform float smudgePressureInfluence;
uniform float smudgeLength;
uniform float smudgeGaussianBlur;
uniform int smudgeSmear;

uniform float canvasAbsorption;
uniform int canvasSkipValleys;
uniform float canvasCatchPeaks;

uniform float temperatureShift;
uniform float brokenColor;

// === Dab Positioning (for global grain mapping) ===
uniform vec2 uDabPos;            // Global coordinates of dab center
uniform float uDabSize;          // Current brush diameter in pixels

// === Rotation ===
uniform float tipRotation;       // Brush tip rotation in radians

// --- Kubelka-Munk Pigment Mixing ---
// Simplified K-M model for GPU: 
// K (Absorpcion) / S (Dispersion) = (1-R)^2 / 2R
// We treat RGB as reflectance R.

vec3 rgbToKS(vec3 rgb) {
    // Avoid division by zero and extreme values
    vec3 r = clamp(rgb, 0.02, 0.98);
    return (vec3(1.0) - r) * (vec3(1.0) - r) / (2.0 * r);
}

vec3 ksToRGB(vec3 ks) {
    // Reverse formula: R = 1 + KS - sqrt(KS^2 + 2*KS)
    return 1.0 + ks - sqrt(ks * ks + 2.0 * ks);
}

vec3 mixColorsKM(vec3 c1, vec3 c2, float t) {
    vec3 ks1 = rgbToKS(c1);
    vec3 ks2 = rgbToKS(c2);
    // Linear interpolation in KS space (corresponds to pigment concentration)
    vec3 mixedKS = mix(ks1, ks2, t);
    return ksToRGB(mixedKS);
}

void main() {
    // === 1. SHAPE & OPACITY (Brush Tip) ===
    float shapeAlpha = 1.0;
    float dist = distance(TexCoords, vec2(0.5));

    if (uHasTip == 1) {
        // CUSTOM BRUSH TIP — sample the tip texture in local UV space
        // Do NOT clip to circle — the texture itself defines the shape
        vec2 uv = TexCoords;
        if (abs(tipRotation) > 0.001) {
            vec2 center = vec2(0.5);
            vec2 d = uv - center;
            float cs = cos(tipRotation);
            float sn = sin(tipRotation);
            uv = center + vec2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
        }

        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            shapeAlpha = 0.0;
        } else {
            vec4 tipSample = texture(tipTexture, uv);
            // Use luminance as alpha mask (grayscale tip textures)
            shapeAlpha = dot(tipSample.rgb, vec3(0.299, 0.587, 0.114));
            // Apply tip's own alpha channel
            shapeAlpha *= tipSample.a;
        }
    } else {
        // PROCEDURAL ROUND TIP — smooth circle with hardness falloff
        // Discard outside circle only for procedural tips
        if (dist > 0.5) discard;
        float feather = (1.0 - hardness) * 0.45 + 0.01;
        shapeAlpha = 1.0 - smoothstep(0.5 - feather, 0.5, dist);
    }

    // Early discard for fully transparent fragments
    if (shapeAlpha < 0.001) discard;

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
    float effectiveFlow = flow; // Pressure is now handled by C++ engine for more control
    float baseAlpha = color.a * shapeAlpha * grainFactor * effectiveFlow;

    // --- PIGMENT MIGRATION (Watercolor Diffusion) ---
    // Pigment flows from center to edges when wet
    if (brushType == 2 || brushType == 5) { // Assuming 2=Watercolor, 5=Custom/Wet
        float migrationRate = bleed * 0.8;
        // Ring highlights the area near the edge (0.4 to 0.5 distance)
        float ring = smoothstep(0.35, 0.5, dist);
        
        // Center becomes slightly more transparent as pigment leaves
        float centerDepletion = mix(1.0, 1.0 - migrationRate * 0.4, 1.0 - ring);
        // Edges become opaque as pigment arrives
        float edgeAccumulation = mix(1.0, 1.0 + migrationRate * 1.5, ring);
        
        baseAlpha *= (centerDepletion * edgeAccumulation);
    }

    // Dilution reduces pigment density (makes color more transparent)
    baseAlpha *= (1.0 - dilution * 0.7);

    // === 5. TEXTURE REVEAL & CANVAS INTERACTION ===
    if (textureRevealEnabled == 1 && uHasGrain == 1) {
       // Inverse relationship: Less pressure = More texture reveal
       float pressureFactor = mix(1.0, pressure, textureRevealPressureInfluence);
       
       // Standard Reveal
       if (grainFactor < 0.9) {
           float revealStr = textureRevealIntensity * (1.0 - pressureFactor);
           baseAlpha *= (1.0 - revealStr);
       }
       
       // Canvas Skip Valleys (Dry Brush Oil)
       if (canvasSkipValleys == 1 && grainFactor < 0.4) {
             baseAlpha *= 0.1; // Almost no paint in deep valleys
       }
       
       // Catch Peaks
       if (canvasCatchPeaks > 0.0 && grainFactor > 0.7) {
            baseAlpha = max(baseAlpha, canvasCatchPeaks * grainFactor);
       }
    }
    
    // === 5.5. BRISTLE SIMULATION ===
    if (bristlesEnabled == 1) {
        // Procedural bristles based on UV and count
        float freq = float(bristleCount) * 0.5;
        float stripe = sin(TexCoords.x * freq * 3.14159 * 2.0 + TexCoords.y * 10.0);
        float bristleNoise = smoothstep(-1.0, 1.0, stripe); // 0..1
        
        if (bristleClumping > 0.0) {
            float clump = sin(TexCoords.x * freq * 0.2);
            bristleNoise = mix(bristleNoise, clump, bristleClumping);
        }
        
        float contrast = 1.0 + bristleStiffness * 3.0;
        bristleNoise = (bristleNoise - 0.5) * contrast + 0.5;
        bristleNoise = clamp(bristleNoise, 0.0, 1.0);
        
        float effectStr = 1.0;
        if (bristleDryBrushEffect == 1) {
            effectStr = 1.0 - pressure;
        }
        
        baseAlpha *= mix(1.0, bristleNoise, 0.5 * effectStr);
    }
    
    // === 5.6 OIL LOADING / DEPLETION ===
    if (loading < 1.0) {
        baseAlpha *= loading;
    }
    
    // === 6. EDGE DARKENING (Water Fringe) ===
    // If enabled, we darken the pigment at the edges of the stroke
    if (edgeDarkeningEnabled == 1 && edgeDarkeningIntensity > 0.01) {
        float edgeness = smoothstep(0.5 - edgeDarkeningWidth, 0.5, dist);
        
        // Darken RGB by increasing apparent density
        float darkFactor = 1.0 + (edgeDarkeningIntensity * edgeness);
        baseAlpha = clamp(baseAlpha * darkFactor, 0.0, 1.0);
        
        // Physically-inspired color deepening
        color.rgb *= mix(1.0, 0.85, edgeDarkeningIntensity * edgeness);
    }
    
    // === 7. BLOOM / GRANULATION ===
    if (granulation > 0.01 && uHasGrain == 1) {
        float grainSignal = grainFactor; // 0..1
        // Moisture-Aware: Granulation is stronger in the wettest parts
        float localWetness = baseAlpha * (1.0 + bleed);
        float settling = (1.0 - grainSignal) * granulation * localWetness * 3.0;
        baseAlpha = clamp(baseAlpha * (1.0 + settling), 0.0, 1.0);
    }

    // === 8. WET MIX ENGINE & OIL MIXING ===
    vec3 finalRGB = color.rgb;
    
    float effectiveWetness = max(wetness, mixing); 
    float effectiveSmudge = max(smudge, smudgeStrength);

    if ((effectiveWetness > 0.01 || effectiveSmudge > 0.01 || bloomEnabled == 1 || blendOnly == 1) && canvasSize.x > 1.0) {
        // Sample canvas
        vec2 screenPos = ((TexCoords - 0.5) * uDabSize + uDabPos) / canvasSize;
        screenPos.y = 1.0 - screenPos.y; 
        vec4 canvasColor = texture(canvasTexture, screenPos);
        vec3 canvasRGB = canvasColor.a > 0.001 ? canvasColor.rgb / canvasColor.a : vec3(1.0);
        float canvasA = canvasColor.a;

        // SMUDGE
        if (effectiveSmudge > 0.01 && canvasA > 0.01) {
            finalRGB = mixColorsKM(finalRGB, canvasRGB, effectiveSmudge * canvasA);
        }

        // MIXING
        if (effectiveWetness > 0.01 && canvasA > 0.01) {
             if (blendOnly == 1) {
                 baseAlpha *= 0.1; 
                 finalRGB = canvasRGB; 
             }
             
             float mixAmount = effectiveWetness * 0.5 * canvasA;
             mixAmount += bleed * 0.3;
             mixAmount = clamp(mixAmount, 0.0, 1.0);
             finalRGB = mixColorsKM(finalRGB, canvasRGB, mixAmount);
             
             if (dirtyMixing == 1) {
                 finalRGB = mixColorsKM(finalRGB, canvasRGB, 0.2);
             }
             
             if (temperatureShift != 0.0) {
                 finalRGB.r += temperatureShift * 0.1;
                 finalRGB.b -= temperatureShift * 0.1;
             }
        }
        
        if (wetness > 0.01 || mixing > 0.01) { 
            float edgeDist = abs(shapeAlpha - 0.5) * 2.0;
            float pooling = effectiveWetness * 0.15 * edgeDist;
            finalRGB *= (1.0 - pooling);
        }
        
        // BLOOM & Wet-on-Wet Expansion
        if (canvasA > 0.1) {
             float expansion = bleed * 0.2 * canvasA;
             baseAlpha = clamp(baseAlpha * (1.0 + expansion), 0.0, 1.0);
             
             if (bloomEnabled == 1) {
                 float noise = fract(sin(dot(TexCoords.xy ,vec2(12.9898,78.233))) * 43758.5453);
                 if (noise < bloomIntensity) {
                     baseAlpha *= (1.0 - bloomIntensity * 0.3);
                 }
             }
        }
    }

    // === FINAL OUTPUT (Premultiplied Alpha) ===
    float finalAlpha = clamp(baseAlpha, 0.0, 1.0);

    // Impasto Volume Accumulation
    float heightAlpha = finalAlpha;
    if (impastoEnabled == 1) {
        heightAlpha *= impastoDepth * 0.5;
    }

    // Premultiplied output
    FragColor = vec4(finalRGB * finalAlpha, heightAlpha);
}
