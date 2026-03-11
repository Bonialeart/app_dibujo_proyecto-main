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
    vec4 effColor = (instanced == 1) ? vColor : color;
    vec2 effDabPos = (instanced == 1) ? vPos : uDabPos;
    float effDabSize = (instanced == 1) ? max(vSize, 1.0) : max(uDabSize, 1.0);
    float effRot = (instanced == 1) ? vRot : tipRotation;

    // === 1. SHAPE & OPACITY (Brush Tip) ===
    float shapeAlpha = 1.0;
    float dist = distance(TexCoords, vec2(0.5));

    if (uHasTip == 1) {
        // CUSTOM BRUSH TIP — sample the tip texture in local UV space
        // GL_CLAMP_TO_BORDER (configurado en C++) devuelve alpha=0 fuera del rang [0,1]
        // así que NO necesitamos descartar manualmente; evita el borde duro al rotar.
        vec2 uv = TexCoords;
        if (abs(effRot) > 0.001) {
            vec2 center = vec2(0.5);
            vec2 d = uv - center;
            float cs = cos(effRot);
            float sn = sin(effRot);
            uv = center + vec2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
        }

        vec4 tipSample = texture(tipTexture, uv); // El GPU clampea a 0 automáticamente
        // Luminancia como máscara de forma (texturas en escala de grises)
        shapeAlpha = dot(tipSample.rgb, vec3(0.299, 0.587, 0.114));
        // Multiplica por el canal alpha del tip (si tiene)
        shapeAlpha *= tipSample.a;
    } else {
        // PROCEDURAL ROUND TIP — círculo suave con hardness y antialiasing premium
        float d = dist * 2.0; // 0.0 en el centro, 1.0 en el borde
        float aaPixel = 2.0 / max(effDabSize, 1.0); // 1 píxel en espacio normalizado
        
        bool isWc = (brushType == 2 || brushType == 5 || wetness > 0.3);
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

    // Early discard for fully transparent fragments
    if (shapeAlpha < 0.001) discard;

    // =========================================================
    // WATERCOLOR EXPANSION — pequeño halo exterior que simula
    // el agua avanzando más allá del pigmento por capilaridad.
    // NO toca el interior del dab para no perder opacidad.
    // =========================================================
    bool isWatercolorExpand = (brushType == 2 || brushType == 5 || wetness > 0.3);
    if (isWatercolorExpand && uHasTip == 0) {
        // Halo muy sutil fuera del borde real: solo alpha extra, sin robar nada
        float outerExtra = smoothstep(0.50, 0.54, dist) * (1.0 - smoothstep(0.54, 0.60, dist));
        shapeAlpha = max(shapeAlpha, outerExtra * wetness * bleed * 0.18);
    }

    // === 2. GRAIN MODULATION (Paper Texture) ===
    float grainFactor = 1.0;

    if (uHasGrain == 1 && grainIntensity > 0.001) {
        // GLOBAL CANVAS MAPPING — grain stays fixed to the paper position
        vec2 globalCoord = ((TexCoords - 0.5) * effDabSize + effDabPos) / (5.0 * grainScale);
        vec4 grainSample = texture(grainTexture, globalCoord);

        // Extract grain value (handles both grayscale and color textures)
        float grainVal = max(grainSample.a, dot(grainSample.rgb, vec3(0.299, 0.587, 0.114)));

        // Multiplicative blend controlled by intensity
        grainFactor = mix(1.0, grainVal, grainIntensity);
    }

    // === 3. FLOW & PRESSURE COMBINATION ===
    float effectiveFlow = flow; // Pressure is now handled by C++ engine for more control
    float baseAlpha = effColor.a * shapeAlpha * grainFactor * effectiveFlow;

    // --- WATERCOLOR PIGMENT MIGRATION ---
    // El pigmento se concentra más en el borde (tide-mark) y
    // la densidad global no se reduce, solo se redistribuye.
    bool isWatercolor = (brushType == 2 || brushType == 5 || wetness > 0.3);
    float watercolorEdgeDarkenFactor = 1.0;
    if (isWatercolor) {
        float migr = bleed * 0.85;  // Aumentado para un borde más fuerte

        // Anillo exterior (tide-mark)
        float ring      = smoothstep(0.38, 0.50, dist);
        float outerRing = smoothstep(0.44, 0.50, dist) * (1.0 - smoothstep(0.50, 0.54, dist));

        // El centro mantiene opacidad, pero el borde se hiper-concentra
        float edgeAccumulation = mix(1.0, 1.0 + migr * 2.5, ring);
        edgeAccumulation += outerRing * migr * 1.5;

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
    
    if (brushType != 7 && edgeDarkeningEnabled == 1 && edgeDarkeningIntensity > 0.01) {
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
    if (brushType != 7 && (max(wetness, mixing) > 0.01 || max(smudge, smudgeStrength) > 0.01 || bloomEnabled == 1 || blendOnly == 1) && canvasSize.x > 1.0) {
        float effectiveWetness = max(wetness, mixing);
        float effectiveSmudge  = max(smudge, smudgeStrength);

        // Coordenadas de pantalla para muestrear el canvas existente
        vec2 screenPos = ((TexCoords - 0.5) * effDabSize + effDabPos) / canvasSize;
        screenPos.y = 1.0 - screenPos.y;
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
        bool isWaterOnly = (dilution > 0.85); 
        if (isWaterOnly) {
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

                float blendStrength = bleed * effectiveWetness;
                blendStrength = clamp(blendStrength, 0.0, 0.92);

                // Mezcla Kubelka-Munk entre el color local y el promedio vecino
                finalRGB = mixColorsKM(canvasRGB, avgRGB, blendStrength);

                // La opacidad del blender es proporcional al pigmento que hay bajo él
                float maxNeighborA = blendedA / weightSum;
                baseAlpha = clamp(maxNeighborA * blendStrength * 0.80, 0.0, maxNeighborA * 0.95);
            } else {
                // Sin pigmento → no pinta NADA
                baseAlpha = 0.0;
                finalRGB  = vec3(0.0);
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
            colorFuseAmount = clamp(colorFuseAmount, 0.0, 0.72);
            finalRGB = mixColorsKM(finalRGB, canvasRGB, colorFuseAmount);

            // ── OSCURECIMIENTO POR ACUMULACIÓN (Layering) ───────────────────
            // Cada capa de acuarela transparente oscurece levemente el total.
            // Efecto Multiply controlado — más sutil que la fusión de colores.
            float darken = existingDensity * effectiveWetness * 0.32;
            darken = clamp(darken, 0.0, 0.55);
            vec3 darkened = finalRGB * canvasRGB;
            finalRGB = mix(finalRGB, darkened, darken);

            // Aumentar alpha donde hay pigmento acumulado (densidad visual)
            baseAlpha = min(baseAlpha + existingDensity * darken * 0.28, 1.0);

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

        // ─── MEZCLADO ESTÁNDAR WET (pinceles de óleo y otros) ────────────────
        if (!isWatercolor && effectiveWetness > 0.01 && canvasA > 0.01) {
            if (blendOnly == 1) {
                baseAlpha *= 0.1;
                finalRGB = canvasRGB;
            }
            float mixAmount = clamp(effectiveWetness * 0.5 * canvasA + bleed * 0.3, 0.0, 1.0);
            finalRGB = mixColorsKM(finalRGB, canvasRGB, mixAmount);
            if (dirtyMixing == 1) finalRGB = mixColorsKM(finalRGB, canvasRGB, 0.2);
            if (temperatureShift != 0.0) {
                finalRGB.r += temperatureShift * 0.1;
                finalRGB.b -= temperatureShift * 0.1;
            }
        }
    }


    // === FINAL OUTPUT (Premultiplied Alpha) ===
    float finalAlpha = clamp(baseAlpha, 0.0, 1.0);
    
    // For erasers, force black output to ensure blend mode (Dest * (1-Alpha)) works perfectly
    if (brushType == 7) finalRGB = vec3(0.0);

    // Impasto Volume Accumulation
    float heightAlpha = finalAlpha;
    if (impastoEnabled == 1 && brushType != 7) {
        heightAlpha *= impastoDepth * 0.5;
    }

    // Premultiplied output
    FragColor = vec4(finalRGB * finalAlpha, heightAlpha);
}
