#version 330 core

in vec2 TexCoords;
out vec4 FragColor;

// === Core Uniforms ===
uniform vec4 color;
uniform float pressure;
uniform float hardness;
uniform float flow;
uniform int brushType;

uniform int instanced;
in vec4 vColor;
in vec2 vPos;
in float vSize;
in float vRot;
in vec2 vWorldPos;
in float vPaintLoad;

// === Brush Tip (Shape Texture) — Local UV Mapping ===
uniform sampler2D tipTexture;
uniform int uHasTip;           // 1 = custom tip, 0 = procedural round

// === Grain (Paper Texture) — Global Canvas Mapping ===
uniform sampler2D grainTexture;
uniform int uHasGrain;         // 1 = grain active
uniform float grainScale;
uniform float grainIntensity;
uniform float uGrainBrightness;
uniform float uGrainContrast;
uniform int uInvertGrain;
uniform float uGrainRotation;
uniform int uGrainEmphasizeDensity;
uniform int uDualGrainEmphasizeDensity;

// === Dual Grain (Secondary Paper Texture) — Global Canvas Mapping ===
uniform sampler2D dualGrainTexture;
uniform int uHasDualGrain;
uniform float dualGrainScale;
uniform float dualGrainIntensity;
uniform float uDualGrainBrightness;
uniform float uDualGrainContrast;
uniform int uInvertDualGrain;
uniform int uDualGrainBlendMode;
uniform float uDualGrainRotation;

// === Dual Brush Tip (Secondary Shape) — Local UV Mapping ===
uniform sampler2D dualTipTexture;
uniform int uHasDualTip;
uniform float dualTipScale;
uniform float dualTipRotation;
uniform int uDualTipBlendMode; // 0 = multiply, 1 = mask (subtract), 2 = add, 3 = height_linear
uniform float uDualTipFlow;
uniform int uGrainBlendMode;   // 0 = multiply, 1 = subtract, 2 = threshold/reveal
uniform int uGrainApplyToTips;
uniform int uDualGrainApplyToTips;

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

// === New Color Mixing and Blend Mode Uniforms ===
uniform int uColorMixing;
uniform float uPaintAmount;
uniform float uColorStretch;
uniform int uBrushBlendMode;

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

// === Shape Adjustments ===
uniform int uInvertShape;
uniform int uFlipX;
uniform int uFlipY;
uniform float uRoundness;
uniform float uShapeContrast;
uniform float uShapeBlur;

float evaluateGrain(sampler2D grainTex, vec2 worldPos, float scale, float rotation, float intensity, float brightness, float contrast, int invert, int blendMode, float press, int applyToTips, vec2 texCoords) {
    vec2 globalCoord;
    if (applyToTips == 1) {
        vec2 localCoord = texCoords;
        float sFactor = scale / 100.0;
        if (sFactor > 0.001) {
            localCoord = (localCoord - vec2(0.5)) / sFactor + vec2(0.5);
        }
        if (rotation != 0.0) {
            float cosR = cos(rotation);
            float sinR = sin(rotation);
            vec2 centered = localCoord - vec2(0.5);
            localCoord = vec2(centered.x * cosR - centered.y * sinR, centered.x * sinR + centered.y * cosR) + vec2(0.5);
        }
        globalCoord = localCoord;
    } else {
        globalCoord = worldPos / (5.0 * scale);
        if (rotation != 0.0) {
            float cosR = cos(rotation);
            float sinR = sin(rotation);
            globalCoord = vec2(globalCoord.x * cosR - globalCoord.y * sinR, globalCoord.x * sinR + globalCoord.y * cosR);
        }
    }
    vec4 grainSample = texture(grainTex, globalCoord);
    float grainVal = (grainSample.a < 0.99) ? grainSample.a : dot(grainSample.rgb, vec3(0.299, 0.587, 0.114));
    if (invert == 1) {
        grainVal = 1.0 - grainVal;
    }
    float bright = brightness / 100.0;
    float con = contrast / 100.0;
    float factor = (1.0 + con);
    grainVal = clamp((grainVal - 0.5) * factor + 0.5 + bright, 0.0, 1.0);

    if (blendMode == 0) {
        return mix(1.0, grainVal, intensity);
    } else if (blendMode == 1) {
        return clamp(1.0 - (1.0 - grainVal) * intensity, 0.0, 1.0);
    } else if (blendMode == 2) {
        float threshold = (1.0 - press) * intensity;
        return smoothstep(threshold - 0.05, threshold + 0.05, grainVal);
    }
    return 1.0;
}

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
    vec4 effColor = (instanced == 1) ? vColor : color;
    vec2 effDabPos = (instanced == 1) ? vPos : uDabPos;
    float effDabSize = (instanced == 1) ? max(vSize, 1.0) : max(uDabSize, 1.0);
    float effRot = (instanced == 1) ? vRot : tipRotation;

    // === 1. SHAPE & OPACITY (Brush Tip) ===
    float shapeAlpha = 1.0;
    float dist = distance(TexCoords, vec2(0.5));

    bool isWcTip = (brushType == 4 || wetness > 0.3);
    if (isWcTip && uHasTip == 0 && uHasGrain == 1 && grainIntensity > 0.01) {
        vec2 globalCoord = vWorldPos / (5.0 * grainScale);
        float grainVal = texture(grainTexture, globalCoord).r;
        dist += (grainVal - 0.5) * grainIntensity * 0.16 * smoothstep(0.18, 0.5, dist);
    }

    if (uHasTip == 1) {
        // CUSTOM BRUSH TIP — sample the tip texture in local UV space
        // GL_CLAMP_TO_BORDER (configurado en C++) devuelve alpha=0 fuera del rang [0,1]
        // así que NO necesitamos descartar manualmente; evita el borde duro al rotar.
        vec2 uv = TexCoords;

        // Apply flip X/Y
        if (uFlipX == 1) uv.x = 1.0 - uv.x;
        if (uFlipY == 1) uv.y = 1.0 - uv.y;

        // Apply roundness (squash Y-axis around center 0.5)
        if (uRoundness < 0.99) {
            uv = uv - vec2(0.5);
            uv.y /= max(uRoundness, 0.05);
            uv = uv + vec2(0.5);
        }

        // Sample tip texture with mipmap bias for blur
        vec4 tipSample = texture(tipTexture, uv, uShapeBlur * 5.0); // El GPU clampea a 0 automáticamente

        // Compute shape alpha from luminance
        float luminance = dot(tipSample.rgb, vec3(0.299, 0.587, 0.114));

        // Apply shape contrast
        if (uShapeContrast != 1.0) {
            luminance = clamp((luminance - 0.5) * uShapeContrast + 0.5, 0.0, 1.0);
        }

        // Apply shape inversion
        if (uInvertShape == 1) {
            shapeAlpha = (1.0 - luminance) * tipSample.a;
        } else {
            shapeAlpha = luminance * tipSample.a;
        }
    } else {
        // PROCEDURAL ROUND TIP — círculo suave con hardness y antialiasing premium
        float d = dist * 2.0; // 0.0 en el centro, 1.0 en el borde
        float aaPixel = 2.0 / max(effDabSize, 1.0); // 1 píxel en espacio normalizado
        
        bool isWc = (brushType == 4 || wetness > 0.3);
        if (isWc) {
            // FORMA DE CHARCO (PUDDLE) PARA ACUARELA:
            // La acuarela no se desvanece linealmente desde el centro. 
            // Es un charco de agua de densidad uniforme que se corta en el borde.
            // Esto permite que el efecto tide-mark actúe en el anillo exterior denso.
            float puddle_core = 0.70; // 70% del dab es totalmente plano
            if (d <= puddle_core) {
                shapeAlpha = 1.0;
            } else {
                float t = clamp((d - puddle_core) / (1.0 - puddle_core), 0.0, 1.0);
                shapeAlpha = 0.5 * (1.0 + cos(t * 3.14159265));
                shapeAlpha = pow(shapeAlpha, 0.45); // Curva muy convexa (borde "duro" pero suave)
            }
        } else if (hardness >= 0.99) {
            // Pincel duro estándar
            shapeAlpha = 1.0 - smoothstep(1.0 - aaPixel, 1.0, d);
        } else {
            // Pincel suave estándar
            float core = hardness;
            if (d <= core) {
                shapeAlpha = 1.0;
            } else {
                float t = clamp((d - core) / max(1.0 - core, 0.001), 0.0, 1.0);
                shapeAlpha = 0.5 * (1.0 + cos(t * 3.14159265));
                shapeAlpha = pow(shapeAlpha, 0.75);
                shapeAlpha *= (1.0 - smoothstep(1.0 - aaPixel, 1.0, d));
            }
        }
    }

    // === DUAL BRUSH TIP COMBINATION ===
    bool dualGrainApplied = false;
    float mainGrainFactor = 1.0;
    if (uHasGrain == 1 && grainIntensity > 0.001) {
        mainGrainFactor = evaluateGrain(grainTexture, vWorldPos, grainScale, uGrainRotation, grainIntensity, uGrainBrightness, uGrainContrast, uInvertGrain, uGrainBlendMode, pressure, uGrainApplyToTips, TexCoords);
    }

    float grainColorMod = 1.0;
    if (uHasGrain == 1 && uGrainEmphasizeDensity == 0) {
        grainColorMod = mainGrainFactor;
    }

    if (uHasDualTip == 1) {
        vec2 dualUV = TexCoords - vec2(0.5);
        if (dualTipRotation != 0.0) {
            float cosR = cos(dualTipRotation);
            float sinR = sin(dualTipRotation);
            dualUV = vec2(dualUV.x * cosR - dualUV.y * sinR, dualUV.x * sinR + dualUV.y * cosR);
        }
        dualUV /= max(dualTipScale, 0.001);
        dualUV += vec2(0.5);

        float dualAlpha = 0.0;
        if (dualUV.x >= 0.0 && dualUV.x <= 1.0 && dualUV.y >= 0.0 && dualUV.y <= 1.0) {
            vec4 dualSample = texture(dualTipTexture, dualUV);
            dualAlpha = (dualSample.a < 0.99) ? dualSample.a : dot(dualSample.rgb, vec3(0.299, 0.587, 0.114));
        }

        if (uHasDualGrain == 1 && dualGrainIntensity > 0.001) {
            float dualGrainFactor = evaluateGrain(dualGrainTexture, vWorldPos, dualGrainScale, uDualGrainRotation, dualGrainIntensity, uDualGrainBrightness, uDualGrainContrast, uInvertDualGrain, uDualGrainBlendMode, pressure, uDualGrainApplyToTips, TexCoords);
            if (uDualGrainEmphasizeDensity == 1) {
                dualAlpha *= dualGrainFactor;
            }
            if (uGrainEmphasizeDensity == 1) {
                shapeAlpha *= mainGrainFactor;
            }
            // Combine dual grain with main grain softly — use min to avoid
            // multiplicative over-darkening that makes the brush look dirty
            if (uDualGrainEmphasizeDensity == 0) {
                grainColorMod = min(grainColorMod, dualGrainFactor);
            }
            dualGrainApplied = true;
        }

        if (uDualTipBlendMode == 0) {
            shapeAlpha *= mix(1.0, dualAlpha, uDualTipFlow);
        } else if (uDualTipBlendMode == 1) {
            shapeAlpha *= mix(1.0, 1.0 - dualAlpha, uDualTipFlow);
        } else if (uDualTipBlendMode == 2) {
            shapeAlpha = clamp(shapeAlpha + dualAlpha * uDualTipFlow, 0.0, 1.0);
        } else if (uDualTipBlendMode == 3) {
            shapeAlpha = clamp(shapeAlpha + (dualAlpha - 1.0) * uDualTipFlow, 0.0, 1.0);
        }
    }

    // Early discard for fully transparent fragments
    if (shapeAlpha < 0.001) discard;

    // =========================================================
    // WATERCOLOR EXPANSION — pequeño halo exterior que simula
    // el agua avanzando más allá del pigmento por capilaridad.
    // NO toca el interior del dab para no perder opacidad.
    // =========================================================
    bool isWatercolorExpand = (brushType == 4 || wetness > 0.3);
    if (isWatercolorExpand && uHasTip == 0) {
        // Halo muy sutil fuera del borde real: solo alpha extra, sin robar nada
        float outerExtra = smoothstep(0.50, 0.54, dist) * (1.0 - smoothstep(0.54, 0.60, dist));
        shapeAlpha = max(shapeAlpha, outerExtra * wetness * bleed * 0.18);
    }

    // === 2. GRAIN MODULATION (Paper Texture) ===
    float grainFactor = 1.0;
    if (!dualGrainApplied) {
        grainFactor = mainGrainFactor;
    }

    // === 3. FLOW & PRESSURE COMBINATION ===
    float effectiveFlow = flow; // Pressure is now handled by C++ engine for more control
    float finalGrainFactor = (uGrainEmphasizeDensity == 1) ? grainFactor : 1.0;
    float baseAlpha = effColor.a * shapeAlpha * finalGrainFactor * effectiveFlow;

    // --- WATERCOLOR PIGMENT MIGRATION ---
    // El pigmento se concentra más en el borde (tide-mark) y
    // la densidad global no se reduce, solo se redistribuye.
    bool isWatercolor = (brushType == 4 || wetness > 0.3);
    float watercolorEdgeDarkenFactor = 1.0;
    if (isWatercolor && uHasTip == 0) {
        float migr = bleed * 0.85;  // Aumentado para un borde más fuerte

        // Anillo exterior (tide-mark)
        float ring      = smoothstep(0.38, 0.50, dist);
        float outerRing = smoothstep(0.44, 0.50, dist) * (1.0 - smoothstep(0.50, 0.54, dist));

        // El centro es más claro (el pigmento migró al borde)
        float centerDepletion = mix(0.40, 1.0, ring);
        float edgeAccumulation = mix(centerDepletion, centerDepletion + migr * 3.5, ring);
        edgeAccumulation += outerRing * migr * 2.0;

        baseAlpha *= clamp(edgeAccumulation, 0.0, 3.0);
        
        // Guardar factor para oscurecer el COLOR más abajo
        watercolorEdgeDarkenFactor = mix(1.0, 1.0 + ring * migr * 4.0, ring);
    }

    // Dilución: efecto suave — no más del 40% de reducción
    baseAlpha *= (1.0 - dilution * 0.4);


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
    
    // === 6. EDGE DARKENING (Water Fringe & Tied-mark) (Skip for Eraser) ===
    vec3 resultColor = effColor.rgb;
    
    // Si es acuarela, aplicar el oscurecimiento fuerte mapeado arriba
    if (isWatercolor && brushType != 7) {
        // En el borde (donde edgeDarkenFactor es alto), el color se multiplica
        // consigo mismo (efecto Burn) para concentrar el pigmento.
        float darkBoost = clamp((watercolorEdgeDarkenFactor - 1.0) * 0.6, 0.0, 1.0);
        vec3 burnedColor = resultColor * resultColor * mix(vec3(0.5), resultColor, 0.2);
        resultColor = mix(resultColor, burnedColor, darkBoost);
    }
    
    if (brushType != 7 && edgeDarkeningEnabled == 1 && edgeDarkeningIntensity > 0.01 && uHasTip == 0) {
        float edgeness = smoothstep(0.5 - edgeDarkeningWidth, 0.5, dist);
        
        // Darken RGB by increasing apparent density
        float darkFactor = 1.0 + (edgeDarkeningIntensity * edgeness * 2.0);
        baseAlpha = clamp(baseAlpha * darkFactor, 0.0, 1.0);
        
        // Physically-inspired color deepening
        vec3 edgeDark = resultColor * resultColor * 0.6; 
        resultColor = mix(resultColor, edgeDark, edgeDarkeningIntensity * edgeness);
    }
    
    // Update local color for final output
    // ... we already have finalRGB below, let's use a local resultColor consistently

    
    // === 7. BLOOM / GRANULATION ===
    if (granulation > 0.01 && uHasGrain == 1) {
        float grainSignal = grainFactor; // 0..1
        // Moisture-Aware: Granulation is stronger in the wettest parts
        float localWetness = baseAlpha * (1.0 + bleed);
        float settling = (1.0 - grainSignal) * granulation * localWetness * 3.0;
        baseAlpha = clamp(baseAlpha * (1.0 + settling), 0.0, 1.0);
    }

    // === FINAL COLOR SELECTION ===
    vec3 finalRGB = resultColor;

    // === 8. WET MIX ENGINE — Acuarela Profesional + Óleo ===
    if (uColorMixing != 0 && brushType != 7 && (max(wetness, mixing) > 0.01 || max(smudge, smudgeStrength) > 0.01 || bloomEnabled == 1 || blendOnly == 1) && canvasSize.x > 1.0) {
        float effectiveWetness = max(wetness, mixing);
        float effectiveSmudge  = max(smudge, smudgeStrength);
        float localPaintAmount = uPaintAmount * pressure;
        float blendModulation = clamp((1.0 - localPaintAmount) * 2.0 + uColorStretch * 2.0, 0.0, 2.0);

        vec2 screenPos = gl_FragCoord.xy / canvasSize;
        vec4 canvasColor = texture(canvasTexture, screenPos);
        vec3 canvasRGB   = canvasColor.a > 0.001 ? canvasColor.rgb / canvasColor.a : vec3(1.0);
        float canvasA    = canvasColor.a;

        // ─── SMUDGE / ARRASTRE ───────────────────────────────────────────────
        if (effectiveSmudge > 0.01 && canvasA > 0.01) {
            finalRGB = mixColorsKM(finalRGB, canvasRGB, effectiveSmudge * canvasA);
        }

        // ─── MODO AGUA PURA (Water Only / Blender) ──────────────────────────
        // Activado cuando dilution > 0.85.
        // El preset tiene default_opacity = 0.0, por lo que baseAlpha llega aquí en ~0.
        // Este bloque ACTIVA (no suprime) la opacidad solo donde hay pigmento.
        bool isBlender = (blendOnly == 1 || dilution > 0.85); 
        if (isBlender) {
            // ── MUESTREO DE VECINOS: kernel 5-tap alrededor del centro del dab ──
            // El pincel de agua MEZCLA el color de los pixeles vecinos con el local.
            // Esto crea el efecto real de "arrastrar y fusionar" pigmento.
            float spreadRadius = effDabSize * bleed * 0.30; // Cuánto se expande en px
            vec2 px = 1.0 / canvasSize; // Tamaño de un pixel en UV

            // Muestrear 8 vecinos equidistantes + centro
            vec2 offsets[9];
            offsets[0] = vec2( 0.0,        0.0);
            offsets[1] = vec2( spreadRadius, 0.0) * px;
            offsets[2] = vec2(-spreadRadius, 0.0) * px;
            offsets[3] = vec2( 0.0,  spreadRadius) * px;
            offsets[4] = vec2( 0.0, -spreadRadius) * px;
            offsets[5] = vec2( spreadRadius * 0.707,  spreadRadius * 0.707) * px;
            offsets[6] = vec2(-spreadRadius * 0.707,  spreadRadius * 0.707) * px;
            offsets[7] = vec2( spreadRadius * 0.707, -spreadRadius * 0.707) * px;
            offsets[8] = vec2(-spreadRadius * 0.707, -spreadRadius * 0.707) * px;

            // Pesos: centro tiene más peso (estabilidad), bordes contribuyen al spread
            float weights[9];
            weights[0] = 0.30; // centro
            weights[1] = weights[2] = weights[3] = weights[4] = 0.10; // cardinales
            weights[5] = weights[6] = weights[7] = weights[8] = 0.0375; // diagonales

            vec3 blendedRGB  = vec3(0.0);
            float blendedA   = 0.0;
            float weightSum  = 0.0;

            for (int i = 0; i < 9; i++) {
                vec4 s  = texture(canvasTexture, screenPos + offsets[i]);
                if (s.a > 0.005) {
                    vec3 sr = s.rgb / s.a;
                    blendedRGB += sr * s.a * weights[i];
                    blendedA   += s.a * weights[i];
                    weightSum  += weights[i];
                }
            }

            if (blendedA > 0.01 && weightSum > 0.001) {
                // Color promedio de la zona — fusión KM con pixel local
                vec3 avgRGB = blendedRGB / (blendedA / weightSum * weightSum / weightSum);
                // Simplificado:
                avgRGB = blendedRGB / weightSum;

                float blendStrength = max(bleed * effectiveWetness, effectiveSmudge);
                blendStrength = clamp(blendStrength * blendModulation, 0.0, 0.92);

                // Mezcla Kubelka-Munk entre el color local y el promedio vecino
                finalRGB = mixColorsKM(canvasRGB, avgRGB, blendStrength);

                // La opacidad del blender es proporcional al pigmento que hay bajo él
                float maxNeighborA = blendedA / weightSum;
                baseAlpha = clamp(maxNeighborA * blendStrength * 0.80, 0.0, maxNeighborA * 0.95);
            } else {
                // Sin pigmento → no pinta NADA en el canvas, pero si es acuarela
                // necesitamos el alpha de la forma para el mapa de agua!
                if (isWatercolor) {
                    baseAlpha = shapeAlpha * grainFactor * effectiveFlow;
                    finalRGB = vec3(0.0);
                } else {
                    baseAlpha = 0.0;
                    finalRGB  = vec3(0.0);
                }
            }
        }

        // ─── ACUARELA: OSCURECIMIENTO AL REPINTAR ────────────────────────────
        // ─── ACUARELA: FUSIÓN Y OSCURECIMIENTO AL REPINTAR ──────────────────
        // Cuando el pincel pasa sobre pintura existente (canvasA > 0):
        //   1. Los COLORES se FUSIONAN (K-M mixing) — rojo+azul = morado
        //   2. Se oscurece ligeramente por acumulación de pigmento
        //   3. El borde se expande (capilaridad)
        if (isWatercolor && canvasA > 0.02) {
            float existingDensity = canvasA;

            // ── FUSIÓN DE COLORES (Wet-on-Wet) ──────────────────────────────
            // bleed controla cuánto se mezclan los colores al pintar encima.
            // Con bleed=0.65: pintar azul sobre rojo da morado suave.
            // mixColorsKM usa el modelo Kubelka-Munk (mezcla de pigmentos real).
            float colorFuseAmount = existingDensity * bleed * effectiveWetness;
            colorFuseAmount = clamp(colorFuseAmount * blendModulation, 0.0, 0.72);
            finalRGB = mixColorsKM(finalRGB, canvasRGB, colorFuseAmount);

            // ── OSCURECIMIENTO POR ACUMULACIÓN (Layering) ───────────────────
            // Solo para puntas procedurales redondas. Para puntas personalizadas
            // el oscurecimiento lo maneja watercolor.frag a nivel de canvas (tide-mark).
            // Aplicar por-dab a custom tips crea un efecto tubo 3D no deseado.
            if (uHasTip == 0) {
                float darken = existingDensity * effectiveWetness * 0.32;
                darken = clamp(darken, 0.0, 0.55);
                vec3 darkened = finalRGB * canvasRGB;
                finalRGB = mix(finalRGB, darkened, darken);

                // Aumentar alpha donde hay pigmento acumulado (densidad visual)
                baseAlpha = min(baseAlpha + existingDensity * darken * 0.28, 1.0);
            }

            // ── DILUCIÓN, EXPANSIÓN Y BLOOM (Circular) ─────────────────────
            if (uHasTip == 0) {
                // ── DILUCIÓN POR AGUA ACUMULADA (Watery Dilution) ────────────────
                // Mientras más pintura húmeda haya debajo y más húmedo esté el pincel,
                // más se disuelve/diluye el pigmento en el centro del trazo,
                // simulando que el agua acumulada empuja el pigmento hacia el borde.
                float moisture = effectiveWetness * existingDensity * 0.65;
                if (moisture > 0.05) {
                    // Diluye el centro (distancia corta del centro)
                    float dilutionRing = smoothstep(0.0, 0.38, dist); // 0 en centro, 1 en borde
                    float localDilution = moisture * (1.0 - dilutionRing); // Disminuye hacia el borde
                    baseAlpha = mix(baseAlpha, baseAlpha * 0.28, localDilution); // Reduce hasta un 72% en el centro
                    
                    // El pigmento disuelto viaja al borde exterior
                    float edgeBoost = moisture * smoothstep(0.38, 0.50, dist) * 1.5;
                    baseAlpha = clamp(baseAlpha + edgeBoost, 0.0, 1.0);
                }

                // ── EXPANSIÓN DEL BORDE HÚMEDO (Capilaridad) ────────────────────
                // El agua en el papel hace que el pigmento se extienda hacia el borde.
                if (bleed > 0.01 && dist > 0.36) {
                    float borderFactor = smoothstep(0.36, 0.50, dist);
                    float spreadBoost  = existingDensity * bleed * borderFactor * 0.38;
                    baseAlpha = min(baseAlpha + spreadBoost, 1.0);
                    // El color del borde se tira hacia el canvas (fusión en el borde)
                    finalRGB = mix(finalRGB, canvasRGB, borderFactor * bleed * 0.28);
                }

                // ── BACKRUN BLOOM ────────────────────────────────────────────────
                // Agua limpia empuja pigmento previo hacia el exterior (efecto
                // cauliflower/backrun visible en acuarela real húmeda).
                if (bloomEnabled == 1 && canvasA > 0.25 && effectiveWetness > 0.55) {
                    float dilutionFactor = max(0.0, 1.0 - dilution * 0.7);
                    float bloomDist = smoothstep(0.42, 0.50, dist);
                    float backrun = bloomIntensity * dilutionFactor * bloomDist * canvasA;
                    baseAlpha = min(baseAlpha + backrun * 0.35, 1.0);
                    finalRGB *= mix(1.0, 0.80, backrun * 0.5);
                }
            }
        }

        // ─── MEZCLADO ESTÁNDAR WET (pinceles de óleo y otros) ────────────────
        if (!isWatercolor && blendOnly == 0 && effectiveWetness > 0.01 && canvasA > 0.01) {
            float mixAmount = clamp(effectiveWetness * 0.5 * canvasA + bleed * 0.3, 0.0, 1.0);
            mixAmount = clamp(mixAmount * blendModulation, 0.0, 1.0);
            finalRGB = mixColorsKM(finalRGB, canvasRGB, mixAmount);
            if (dirtyMixing == 1) finalRGB = mixColorsKM(finalRGB, canvasRGB, 0.2);
            if (temperatureShift != 0.0) {
                finalRGB.r += temperatureShift * 0.1;
                finalRGB.b -= temperatureShift * 0.1;
            }
        }
    }

    if (brushType == 5) {
        // --- PHYSICAL OIL PAINT SIMULATION ---
        float effPaintLoad = (instanced == 1) ? vPaintLoad : loading;
        if (uColorMixing != 0 && canvasSize.x > 1.0) {
            vec2 screenPos = gl_FragCoord.xy / canvasSize;
            vec4 canvasColor = texture(canvasTexture, screenPos);
            vec3 canvasRGB = canvasColor.a > 0.001 ? canvasColor.rgb / canvasColor.a : vec3(1.0);
            
            // Simular la mezcla física de pigmentos usando Kubelka-Munk
            vec3 mixedColor = mixColorsKM(canvasRGB, effColor.rgb, effPaintLoad);
            
            // El arrastre (smudge) depende de la humedad (wetness) e influjo de paint amount / stretch
            float localPaintAmount = uPaintAmount * pressure;
            float oilBlend = wetness * clamp(1.0 - localPaintAmount * 0.8 + uColorStretch * 0.8, 0.0, 1.0);
            finalRGB = mix(effColor.rgb, mixedColor, oilBlend);
            
            // Calcular el alfa resultante
            baseAlpha = max(canvasColor.a, shapeAlpha * effPaintLoad) * effColor.a * flow;
            
            // --- ARRASTRE DE PASTA (PAINT DRAGGING) ---
            // Cuando hay smudge activo, la pasta existente se arrastra
            // físicamente: la altura se redistribuye en lugar de solo acumularse
            if (smudge > 0.01 && canvasColor.a > 0.01) {
                // Muestrear vecinos en la dirección del arrastre para simular
                // que la pintura se "pega" al pincel y se arrastra
                vec2 px = 1.0 / canvasSize;
                float dragRadius = effDabSize * smudge * 0.15;
                
                // Promedio de altura en un pequeño radio alrededor
                float neighHeight = 0.0;
                int neighCount = 0;
                for (int sy = -1; sy <= 1; sy++) {
                    for (int sx = -1; sx <= 1; sx++) {
                        vec4 nc = texture(canvasTexture, screenPos + vec2(sx, sy) * px * dragRadius);
                        neighHeight += nc.a;
                        neighCount++;
                    }
                }
                neighHeight /= float(neighCount);
                
                // La altura nueva es una mezcla entre la altura arrastrada (vecinos)
                // y la depositada por el pincel
                float dragFactor = smudge * 0.4;
                baseAlpha = mix(max(canvasColor.a, shapeAlpha * effPaintLoad) * effColor.a * flow,
                               neighHeight * (1.0 - localPaintAmount * 0.5), dragFactor);
            }
        } else {
            // Safe fallback when no canvas is present or color mixing is disabled
            finalRGB = effColor.rgb;
            baseAlpha = shapeAlpha * effPaintLoad * effColor.a * flow;
        }
    }

    // === CANTIDAD DE PINTURA — modulación final universal ===
    baseAlpha *= uPaintAmount;

    // === EXTENDER COLOR — mezcla con canvas siempre (antes de final output) ===
    if (uColorStretch > 0.01 && canvasSize.x > 1.0) {
        vec2 screenPos = gl_FragCoord.xy / canvasSize;
        vec4 canvasColor = texture(canvasTexture, screenPos);
        float stretch = uColorStretch * 0.6;
        vec3 canvasRGB = canvasColor.a > 0.001 ? canvasColor.rgb / canvasColor.a : vec3(1.0);
        finalRGB = mix(finalRGB, canvasRGB, clamp(stretch, 0.0, 0.85));
        baseAlpha *= (1.0 - stretch * 0.4);
    }

    // === FINAL OUTPUT (Premultiplied Alpha) ===
    float finalAlpha = clamp(baseAlpha, 0.0, 1.0);

    // Apply grain color modulation when emphasize density is disabled
    // For watercolor brushes, skip per-dab grain — it's applied once at canvas
    // level in watercolor.frag to avoid noisy grain stacking from spray particles
    bool skipDabGrain = (brushType == 4 || wetness > 0.3);
    if (brushType != 7 && !skipDabGrain) {
        finalRGB *= grainColorMod;
    }

    // For erasers, force black output to ensure blend mode (Dest * (1-Alpha)) works perfectly
    if (brushType == 7) finalRGB = vec3(0.0);

    // Impasto Volume Accumulation — altura persistente en el canal alpha
    float outAlpha = finalAlpha;
    if (impastoEnabled == 1 && brushType != 7 && canvasSize.x > 1.0) {
        vec2 impPos = gl_FragCoord.xy / canvasSize;
        float existingH = texture(canvasTexture, impPos).a;

        // Depósito de pintura basado en cobertura y profundidad impasto
        float paintDeposit = finalAlpha * impastoDepth * 0.5;

        // Acumulación en bordes: la pasta se amontona en los filos del pincel
        float edgeFact = smoothstep(0.3, 0.5, dist);
        paintDeposit *= (1.0 + edgeFact * impastoEdgeBuildup);

        // Crestas direccionales de las cerdas
        if (impastoDirectionalRidges == 1 && bristlesEnabled == 1) {
            float freq = float(bristleCount) * 0.5;
            float ridge = abs(sin(TexCoords.x * freq * 3.14159));
            paintDeposit *= (1.0 + ridge * 0.4);
        }

        // Acumular altura: para arrastre (smudge) conservamos altura existente
        if (blendOnly == 1 || smudge > 0.5) {
            // Modo espátula/blender: redistribuir en lugar de acumular
            outAlpha = mix(existingH, max(existingH, paintDeposit), 0.3);
        } else if (impastoPreserveExisting == 1) {
            // Conservar picos existentes
            outAlpha = max(existingH, paintDeposit);
        } else {
            // Acumulación aditiva con saturación
            outAlpha = existingH + paintDeposit * (1.0 - existingH);
        }
        outAlpha = clamp(outAlpha, 0.0, 1.0);
    }

    FragColor = vec4(finalRGB * outAlpha, outAlpha);
}
