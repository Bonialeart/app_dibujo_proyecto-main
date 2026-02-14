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
        // Higher count = higher frequency noise
        float freq = float(bristleCount) * 0.5;
        // Rotate coords to align with brush rotation (approximated by uRotation if available, else just simple)
        // Simple 1D noise striping along flow
        float stripe = sin(TexCoords.x * freq * 3.14159 * 2.0 + TexCoords.y * 10.0);
        float bristleNoise = smoothstep(-1.0, 1.0, stripe); // 0..1
        
        // Clumping makes it less uniform
        if (bristleClumping > 0.0) {
            float clump = sin(TexCoords.x * freq * 0.2);
            bristleNoise = mix(bristleNoise, clump, bristleClumping);
        }
        
        // Stiffness: High stiffness = hard bristle lines (high contrast)
        // Low stiffness = soft (blurrier)
        float contrast = 1.0 + bristleStiffness * 3.0;
        bristleNoise = (bristleNoise - 0.5) * contrast + 0.5;
        bristleNoise = clamp(bristleNoise, 0.0, 1.0);
        
        // Modulate Alpha
        // If bristleDryBrushEffect is on, we see it more at low pressure
        float effectStr = 1.0;
        if (bristleDryBrushEffect == 1) {
            effectStr = 1.0 - pressure;
        }
        
        baseAlpha *= mix(1.0, bristleNoise, 0.5 * effectStr);
    }
    
    // === 5.6 OIL LOADING / DEPLETION ===
    // Simple simulation: lower opacity if loading is low or depletion is high
    if (loading < 1.0) {
        baseAlpha *= loading;
    }
    
    // === 5.7 IMPASTO LIGHTING (Fake 3D) ===
    vec3 lightDir = normalize(vec3(-1.0, -1.0, 1.0)); // Top-left light
    if (impastoEnabled == 1) {
        // Estimate gradient of alpha to get normal
        // Since we are in fragment shader without derivatives of the shape *before* drawing, 
        // we use the distance from center (approx shape) for gradient.
        // Or we use dFdx/dFdy on the calculated baseAlpha (if not too noisy)
        
        // Let's use analytical sphere/circle normal for the dab
        vec2 d = TexCoords - 0.5;
        float distSq = dot(d, d);
        float height = sqrt(max(0.0, 0.25 - distSq)) * 2.0; // Hemisphere 0..1
        height *= pressure; // Flatten by pressure? Or Height by amount of paint
        height *= impastoDepth;
        
        // Perturb height with grain
        if (uHasGrain == 1) {
            height += (grainFactor - 0.5) * impastoTextureStrength * 0.2;
        }
        
        // Calculate Normal from height
        // This is a per-dab normal. For stroke-wide it might look like bubbles.
        // Better: Use directional ridges (stripes)
        if (impastoDirectionalRidges == 1) {
            float ridge = sin(TexCoords.y * 20.0);
             height += ridge * 0.1 * impastoDepth;
        }
        
        // Since we can't easily do neighbor sampling, we cheat lighting:
        // Light coming from top-left means top-left of dab is bright, bottom-right is dark.
        // Dot product of (d.x, d.y, z) with Light
        
        vec3 normal = normalize(vec3(d.x, -d.y, 1.0 - height)); // Approx
        // Normal pointing up is (0,0,1)
        
        float diffuse = max(dot(normal, lightDir), 0.0);
        float specular = pow(diffuse, 20.0) * impastoShine;
        
        // Modify Color
        color.rgb *= (0.5 + 0.5 * diffuse); // Ambient + Diffuse
        color.rgb += vec3(specular);
    }

    // === 6. EDGE DARKENING ===
    // If enabled, we darken the pigment at the edges of the stroke
    if (edgeDarkeningEnabled == 1 && edgeDarkeningIntensity > 0.01) {
        // We need distance from center 0..0.5
        float dist = distance(TexCoords, vec2(0.5));
        // Normalize to 0..1 (approx edge)
        float edgeness = smoothstep(0.5 - edgeDarkeningWidth, 0.5, dist);
        
        // Darken RGB, keep alpha (or boost alpha?) -> Darkening usually implies more pigment
        // Let's boost alpha and darken color
        float darkFactor = 1.0 + (edgeDarkeningIntensity * edgeness);
        baseAlpha = min(baseAlpha * darkFactor, 1.0);
        // Make color darker/saturated
        // finalRGB *= (1.0 - (edgeDarkeningIntensity * 0.5 * edgeness));
    }
    
    // === 7. BLOOM / GRANULATION ===
    // Real bloom needs neighbor info, but we can simulate "pigment separation" aka granulation
    if (granulation > 0.01 && uHasGrain == 1) {
       // Boost grain contrast
        float grainSignal = grainFactor; // 0..1
        // Make valleys darker (pigment settles)
        float settling = (1.0 - grainSignal) * granulation * 2.0;
        baseAlpha = min(baseAlpha * (1.0 + settling), 1.0);
    }

    // === 8. WET MIX ENGINE & OIL MIXING ===
    vec3 finalRGB = color.rgb;
    
    // Combine wetness params
    float effectiveWetness = max(wetness, mixing); // Use mixing for oil
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
            finalRGB = mix(finalRGB, canvasRGB, effectiveSmudge * canvasA);
        }

        // MIXING
        if (effectiveWetness > 0.01 && canvasA > 0.01) {
             // Oil Mixing: 
             // If dirtyMixing is on, we pick up color.
             // If blendOnly is on, we barely deposit pigment, just push existing.
             
             if (blendOnly == 1) {
                 baseAlpha *= 0.1; // Reduce deposition
                 finalRGB = canvasRGB; // Just picking up
             }
             
             float mixAmount = effectiveWetness * 0.5 * canvasA;
             mixAmount += bleed * 0.3;
             mixAmount = clamp(mixAmount, 0.0, 1.0);
             finalRGB = mix(finalRGB, canvasRGB, mixAmount);
             
             if (dirtyMixing == 1) {
                 // Push canvas color into 'finalRGB' more strongly
                 finalRGB = mix(finalRGB, canvasRGB, 0.2);
             }
             
             // Scrape Through: Removing paint
             if (scrapeThrough == 1) {
                 // Sample alpha is inverted? 
                 // Effectively we want to reduce the destination alpha.
                 // In standard blending we can't easily reduce dest alpha without specific blend modes.
                 // But we can output a color that blends to "erase".
                 // Hard to do in single pass forward painting without specific blend func.
             }
             
             // Color Dynamics: Temperature Shift (Warm/Cool)
             if (temperatureShift != 0.0) {
                 // Simple R/B shift
                 finalRGB.r += temperatureShift * 0.1;
                 finalRGB.b -= temperatureShift * 0.1;
             }
        }
        
        // Wet paint darkens slightly at edges
        if (wetness > 0.01 || mixing > 0.01) { // Apply for oil too
            float edgeDist = abs(shapeAlpha - 0.5) * 2.0;
            float pooling = effectiveWetness * 0.15 * edgeDist;
            finalRGB *= (1.0 - pooling);
        }
        
        // BLOOM Simulation (Simple)
        // If underlying pixel is wet/exists, and we have bloom enabled, we displace pigment
        if (bloomEnabled == 1 && canvasA > 0.1) {
             // If we are painting 'water' or wet paint on existing paint, 
             // we push the pigment away (reduce alpha here) or create a ring
             float noise = fract(sin(dot(TexCoords.xy ,vec2(12.9898,78.233))) * 43758.5453);
             if (noise < bloomIntensity) {
                 // Creating 'holes' or variations
                 baseAlpha *= (1.0 - bloomIntensity * 0.3);
             }
        }
    }

    // === FINAL OUTPUT (Premultiplied Alpha) ===
    float finalAlpha = clamp(baseAlpha, 0.0, 1.0);

    // Premultiplied output
    FragColor = vec4(finalRGB * finalAlpha, finalAlpha);
}
