// ============================================================================
// watercolor.frag — Motor de Acuarela Profesional (ArtFlow Studio)
// ============================================================================
// Implementa el comportamiento real de acuarela:
//   1. Acumulación de pigmento al pintar sobre la misma área (se oscurece)
//   2. Expansión húmeda (spreading) del pigmento cuando hay agua
//   3. Tide-mark / borde de secado oscuro en la periferia húmeda
//   4. Wet-on-wet: pigmentos que se fusionan cuando ambos están húmedos
//   5. Bloom / backrun: el agua limpia empuja al pigmento hacía afuera
// ============================================================================
#version 330 core

in vec2 vTexCoord;        // UV del fragmento actual [0,1]
out vec4 fragColor;

// ── Texturas ──
uniform sampler2D uCanvas;         // Capa actual con el pigmento acumulado
uniform sampler2D uWetMap;         // Mapa de humedad R=humedad G=tiempo_secado
uniform sampler2D uBrushDab;       // El dab que se está pintando AHORA
uniform sampler2D uGrainTexture;   // Textura de grano de papel (opcional)

// ── Parámetros del pincel ──
uniform vec4  uBrushColor;         // Color del pincel (RGBA)
uniform float uWetness;            // Cuánta agua tiene el pincel (0..1)
uniform float uPigment;            // Concentración de pigmento (0..1)
uniform float uBleed;              // Qué tanto se expande en áreas húmedas
uniform float uDilution;           // Cuánto el agua diluye el pigmento
uniform float uGranulation;        // Tendencia del pigmento a granular en papel
uniform float uAbsorption;         // Velocidad de absorción del papel (0=lento, 1=rápido)
uniform float uDryingRate;         // Velocidad de secado entre pasadas (0..1)
uniform float uEdgeDarkening;      // Intensidad del tide-mark en borde seco
uniform float uFlow;               // Flujo del pincel
uniform float uPressure;           // Presión actual (0..1)
uniform float uGrainIntensity;     // Intensidad del grano de papel
uniform float uGrainScale;         // Escala del grano de papel
uniform float uGrainBrightness;    // Brillo del grano (-100..100)
uniform float uGrainContrast;      // Contraste del grano (-100..100)
uniform int uInvertGrain;          // Invertir grano (0 o 1)
uniform int uGrainEmphasizeDensity; // Enfatizar densidad del grano (0 o 1)

// ── New Color Mixing and Blend Mode Uniforms ──
uniform int uColorMixing;
uniform float uPaintAmount;
uniform float uColorStretch;
uniform int uBrushBlendMode;

// ── Parámetros del canvas ──
uniform vec2  uCanvasSize;         // Tamaño del canvas en píxeles
uniform float uTime;               // Tiempo global para animación de secado

// ── Modo de operación ──
// 0 = PINTAR (paint_dab)    — combinar dab con canvas+wetmap
// 1 = DIFUNDIR (spread_wet) — expandir pigmento según wetmap
// 2 = SECAR (dry_step)      — avanzar el secado del mapa de humedad
uniform int uMode;
uniform int uBlendOnly;

// ── Constantes ──
const float PI = 3.14159265;
const float INV_SQRT2 = 0.70710678;

// ============================================================================
// UTILIDADES
// ============================================================================

// Luminancia perceptual (declarada antes de su primer uso)
float lumaOf(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Saturación aproximada (croma normalizado)
float satOf(vec3 c) {
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    return (mx - mn) / max(mx, 0.001);
}

// Mezcla de colores estilo Kubelka-Munk (más realista que interpolación lineal)
// Simula cómo los pigmentos físicos mezclan sus reflexiones.
// Con preservación de croma: la mezcla K-M de tonos lejanos tiende a virar
// hacia grises sucios; restituimos parte de la saturación esperada para que
// las fusiones húmedas se mantengan limpias y vibrantes.
vec3 mixKubelkaMunk(vec3 colorA, vec3 colorB, float t) {
    // Transformar a espacio KM (k/s ratio)
    vec3 kmA = (1.0 - colorA) * (1.0 - colorA) / max(2.0 * colorA, vec3(0.001));
    vec3 kmB = (1.0 - colorB) * (1.0 - colorB) / max(2.0 * colorB, vec3(0.001));
    vec3 kmMix = mix(kmA, kmB, t);
    // Volver al espacio RGB
    vec3 rgbMix = 1.0 + kmMix - sqrt(kmMix * kmMix + 2.0 * kmMix);
    rgbMix = clamp(rgbMix, 0.0, 1.0);

    // Croma esperado: interpolación de las saturaciones de entrada
    float satMix    = satOf(rgbMix);
    float satTarget = mix(satOf(colorA), satOf(colorB), t);
    if (satTarget > satMix + 0.001) {
        // Recuperar el 60% del croma perdido, escalando alrededor de la luma
        float satGoal = mix(satMix, satTarget, 0.6);
        float k = clamp(satGoal / max(satMix, 0.02), 1.0, 2.0);
        float lum = lumaOf(rgbMix);
        rgbMix = clamp(vec3(lum) + (rgbMix - vec3(lum)) * k, 0.0, 1.0);
    }
    return rgbMix;
}

// Superposición física de pigmentos estilo Kubelka-Munk (modelo aditivo/sustractivo)
// Simula cómo las capas transparentes de acuarela se acumulan y oscurecen al cruzarse
vec3 layerKubelkaMunk(vec3 canvasColor, vec3 brushColor, float amount) {
    vec3 c = clamp(canvasColor, 0.01, 0.99);
    vec3 b = clamp(brushColor, 0.01, 0.99);
    
    // Convertir a coeficientes K/S de absorción/dispersión de pigmento
    vec3 kmCanvas = (1.0 - c) * (1.0 - c) / (2.0 * c);
    vec3 kmBrush  = (1.0 - b) * (1.0 - b) / (2.0 * b);
    
    // Sumamos la densidad de pigmento
    vec3 kmFinal  = kmCanvas + kmBrush * amount;
    
    // Volver al espacio RGB
    vec3 rgbFinal = 1.0 + kmFinal - sqrt(kmFinal * kmFinal + 2.0 * kmFinal);
    return clamp(rgbFinal, 0.0, 1.0);
}

// Muestreo con offset en píxeles
vec4 sampleOffset(sampler2D tex, vec2 uv, vec2 offsetPx) {
    return texture(tex, uv + offsetPx / uCanvasSize);
}

// Coordenada global alineada de grano de papel
vec2 getGlobalCoord(vec2 uv) {
    return (uv * uCanvasSize) / (5.0 * uGrainScale);
}

// Obtener el valor del grano con brillo y contraste aplicados
float getGrainValue(vec2 coord) {
    vec4 grainSample = texture(uGrainTexture, coord);
    float grainVal = (grainSample.a < 0.99) ? grainSample.a : dot(grainSample.rgb, vec3(0.299, 0.587, 0.114));
    
    // Aplicar inversión si es necesario
    if (uInvertGrain == 1) {
        grainVal = 1.0 - grainVal;
    }
    
    // Aplicar contraste y brillo (escala y bias)
    float bright = uGrainBrightness / 100.0;
    float contrast = uGrainContrast / 100.0;
    float factor = (1.0 + contrast);
    
    grainVal = clamp((grainVal - 0.5) * factor + 0.5 + bright, 0.0, 1.0);
    return grainVal;
}

// ============================================================================
// MODO 0: PAINT DAB — Combinar el dab actual con el canvas existente
// ============================================================================
// Comportamiento clave:
//   • Si hay humedad existente (uWetMap.r > 0), el pigmento se funde y OSCURECE
//   • Si el area está seca, el pigmento se acumula encima (Multiply blend)
//   • La dilución reduce la densidad del pigmento pero aumenta la humedad
// ============================================================================
vec4 paintDab() {
    vec4 canvasSample = texture(uCanvas, vTexCoord);
    vec4 wetSample    = texture(uWetMap, vTexCoord);  // R=wetness G=sec_age
    vec4 dabSample    = texture(uBrushDab, vTexCoord);

    float localPaintAmount = uPaintAmount * uPressure;
    float dabAlpha    = dabSample.a * uFlow * uPressure;
    float localWet    = wetSample.r;   // Humedad preexistente en este pixel
    float secAge      = wetSample.g;   // Edad del pigmento húmedo (0=fresco 1=viejo)

    // ── GRANO DE PAPEL ──
    float grain = 1.0;
    if (uGrainIntensity > 0.001) {
        vec2 globalCoord = getGlobalCoord(vTexCoord);
        float gv = getGrainValue(globalCoord);
        float localGrainIntensity = uGrainIntensity * (1.0 - localPaintAmount * 0.5);
        grain = mix(1.0, gv, localGrainIntensity);
    }
    if (uGrainEmphasizeDensity == 1) {
        dabAlpha *= grain;
    }

    // ── DILUCIÓN: el agua diluye el pigmento del pincel ──
    // Mayor dilución = pigmento más transparente pero mayor depósito de agua
    float effectivePigment = (uBlendOnly == 1) ? 1.0 : (uPigment * (1.0 - uDilution * 0.7));
    effectivePigment *= localPaintAmount;
    dabAlpha *= effectivePigment;

    // ── AGUADA: con mucha agua el lavado se aplica translúcido y uniforme ──
    // El pigmento queda suspendido en la película de agua; la densidad final
    // la aportan después el asentamiento en el anillo perimetral (wet edge)
    // y la sedimentación en los poros del papel, no la pasada del pincel.
    float washiness = clamp(uWetness * (0.4 + 0.8 * uDilution), 0.0, 1.0);
    if (uBlendOnly == 0) {
        dabAlpha *= (1.0 - washiness * 0.30);
    }

    if (dabAlpha < 0.001) {
        // Sin cobertura de pincel — el depósito de humedad lo gestiona el
        // pase de WetMap en C++; el canvas no cambia.
        return canvasSample;
    }

    // Si es agua pura, no pintamos nada sobre lienzo transparente
    if (uBlendOnly == 1 && canvasSample.a <= 0.001) {
        return canvasSample;
    }

    // ── COLOR DEL PINCEL ──
    vec3 brushRGB = uBrushColor.rgb;
    if (dabSample.a > 0.001) {
        brushRGB = clamp(dabSample.rgb / dabSample.a, 0.0, 1.0);
    }

    // ── GRANULACIÓN DINÁMICA: depende del agua cargada y de la presión ──
    // Pincel muy húmedo → el pigmento fluye y SEDIMENTA en los valles del papel.
    // Pincel seco / poca presión → el pigmento queda atrapado en las CRESTAS
    // y salta los valles (efecto pincel seco), invirtiendo el patrón.
    if (uGranulation > 0.01 && uGrainIntensity > 0.001) {
        vec2 globalCoord = getGlobalCoord(vTexCoord);
        float gv = getGrainValue(globalCoord);
        float waterLoad = clamp(uWetness * uFlow * (0.4 + 0.6 * uPressure), 0.0, 1.0);
        float localGranulation = uGranulation * (1.0 - localPaintAmount * 0.5);
        float valleyTerm = (0.5 - gv) * 2.0;   // +1 en valle, -1 en cresta
        float granFactor = 1.0 + localGranulation *
                           mix(-valleyTerm * 0.8, valleyTerm * 1.2, waterLoad);
        dabAlpha = clamp(dabAlpha * granFactor, 0.0, 1.0);
    }

    // ── INTERACCIÓN WET-ON-WET ──
    // Si la zona ya está húmeda, el nuevo pigmento se funde con el existente
    vec3 finalRGB = brushRGB;
    float finalAlpha = dabAlpha;

    if (uColorMixing != 0 && canvasSample.a > 0.001) {
        // Despremutiplicar color del canvas
        vec3 canvasRGB = canvasSample.rgb / canvasSample.a;
        float blendModulation = clamp((1.0 - localPaintAmount) * 2.0 + uColorStretch * 2.0, 0.0, 2.0);

        if (localWet > 0.05) {
            // ━━━ ÁREA HÚMEDA: Wet-on-wet ━━━
            // Los colores se fusionan físicamente (Kubelka-Munk)
            // La frescura del agua determina cuánto se mezclan
            float freshness = 1.0 - secAge;               // 1=reciente, 0=viejo
            float blendFactor = localWet * freshness * 0.8;
            blendFactor = clamp(blendFactor * blendModulation, 0.0, 1.0);

            // Mezcla física de pigmentos
            vec3 mixedRGB = mixKubelkaMunk(brushRGB, canvasRGB, blendFactor);
            
            if (uBlendOnly == 1) {
                finalRGB = mixedRGB;
            } else {
                // EVITAR SOBRE-ACUMULACIÓN EN EL MISMO TRAZO:
                // Si la zona es muy fresca (freshness cercana a 1.0, parte del trazo actual),
                // atenuamos drásticamente el layerKubelkaMunk para que el color se mezcle
                // de forma fluida pero no se oscurezca repetidamente sobre sí mismo mientras no se levante el lápiz.
                float wetAccumulation = uPressure * 0.40 * (1.0 - freshness * 0.95);
                wetAccumulation = clamp(wetAccumulation * (1.0 + localPaintAmount), 0.0, 1.0);
                finalRGB = layerKubelkaMunk(mixedRGB, brushRGB, wetAccumulation);
            }

            // En zonas húmedas, el pigmento se expande (alpha mayor en bordes)
            // El Bleed controla cuánto se expande el borde mojado
            float spreadBoost = localWet * uBleed * 0.5;
            finalAlpha = min(finalAlpha + spreadBoost * 0.3, 1.0);

        } else {
            // ━━━ ÁREA SECA: Acumulación de pigmento ━━━
            if (uBlendOnly == 1) {
                finalRGB = brushRGB;
                finalAlpha = dabAlpha;
            } else {
                // Súper acumulación física utilizando el modelo aditivo K-M
                // Aumenta proporcionalmente a la presión del lápiz para oscurecer
                float accumulation = (1.0 - uDilution * 0.40) * uPressure * 1.55;
                accumulation = clamp(accumulation * (1.0 + localPaintAmount), 0.0, 3.0);
                finalRGB = layerKubelkaMunk(canvasRGB, brushRGB, accumulation);

                // En zonas secas, la opacidad se acumula también (se oscurece)
                float blendToMultiply = (1.0 - uDilution * 0.5) * uPressure;
                float extraAlpha = canvasSample.a * blendToMultiply * 0.55;
                finalAlpha = min(finalAlpha + extraAlpha, 1.0);
            }
        }
    }

    // ── WET EDGE: acumulación de pigmento en el borde del agua ──
    // El pigmento migra con el agua hacia el perímetro del charco y se
    // deposita donde la humedad cae bruscamente (este píxel está más seco
    // que su vecino más húmedo). La rampa smoothstep crea un anillo denso
    // con transición SUAVE hacia el interior, y el grano del papel rompe
    // su regularidad para que el cerco sea orgánico, no circular.
    if (uEdgeDarkening > 0.01 && uBlendOnly == 0) {
        vec2 ts = 2.0 / uCanvasSize;
        float wMax = max(
            max(texture(uWetMap, vTexCoord + vec2(ts.x, 0.0)).r,
                texture(uWetMap, vTexCoord - vec2(ts.x, 0.0)).r),
            max(texture(uWetMap, vTexCoord + vec2(0.0, ts.y)).r,
                texture(uWetMap, vTexCoord - vec2(0.0, ts.y)).r));
        float edge = smoothstep(0.04, 0.45, wMax - localWet);
        if (edge > 0.001) {
            float organic = 1.0;
            if (uGrainIntensity > 0.001) {
                float gvEdge = getGrainValue(getGlobalCoord(vTexCoord));
                organic = mix(1.0, 0.6 + 0.8 * gvEdge, uGrainIntensity);
            }
            float edgeAmount = edge * uEdgeDarkening * 0.45
                             * (0.4 + uWetness * 0.6) * organic;
            finalRGB  *= (1.0 - edgeAmount * 0.5);
            finalAlpha = min(finalAlpha * (1.0 + edgeAmount), 1.0);
        }
    }

    // ── COMPOSICIÓN FINAL ──
    // Premultiply alpha para compositing correcto
    float outAlpha = canvasSample.a + finalAlpha * (1.0 - canvasSample.a);
    vec3 outRGB;

    if (outAlpha > 0.001) {
        vec3 srcPre = finalRGB * finalAlpha;
        vec3 dstPre = canvasSample.rgb;
        vec3 srcRGB = finalRGB;
        vec3 dstRGB = canvasSample.a > 0.001 ? canvasSample.rgb / canvasSample.a : vec3(1.0);
        
        vec3 overRGB = srcPre + dstPre * (1.0 - finalAlpha);
        
        if (uBrushBlendMode == 0) { // Normal glazing watercolor
            vec3 multipliedRGB = mix(dstRGB, srcRGB * dstRGB, finalAlpha);
            outRGB = mix(overRGB, multipliedRGB * outAlpha, canvasSample.a);
        } else {
            vec3 blendModeResult;
            if (uBrushBlendMode == 1) { // Multiply
                blendModeResult = srcRGB * dstRGB;
            } else if (uBrushBlendMode == 2) { // Screen
                blendModeResult = srcRGB + dstRGB - srcRGB * dstRGB;
            } else if (uBrushBlendMode == 3) { // Overlay
                blendModeResult = vec3(
                    dstRGB.r <= 0.5 ? 2.0 * srcRGB.r * dstRGB.r : 1.0 - 2.0 * (1.0 - srcRGB.r) * (1.0 - dstRGB.r),
                    dstRGB.g <= 0.5 ? 2.0 * srcRGB.g * dstRGB.g : 1.0 - 2.0 * (1.0 - srcRGB.g) * (1.0 - dstRGB.g),
                    dstRGB.b <= 0.5 ? 2.0 * srcRGB.b * dstRGB.b : 1.0 - 2.0 * (1.0 - srcRGB.b) * (1.0 - dstRGB.b)
                );
            } else if (uBrushBlendMode == 4) { // Darken
                blendModeResult = min(dstRGB, srcRGB);
            } else if (uBrushBlendMode == 5) { // Lighten
                blendModeResult = max(dstRGB, srcRGB);
            } else {
                blendModeResult = srcRGB;
            }
            
            vec3 blendedColor = canvasSample.a > 0.001 ? mix(dstRGB, blendModeResult, finalAlpha) : srcRGB;
            outRGB = blendedColor * outAlpha;
        }
    } else {
        outRGB = vec3(0.0);
    }

    return vec4(outRGB, outAlpha);
}

// ============================================================================
// MODO 1: SPREAD WET — Difusión del pigmento en zonas húmedas
// ============================================================================
// Simula la difusión física del pigmento que fluye y se expande con el agua,
// limitada por la fricción
vec4 spreadWet() {
    vec4 centerCenter = texture(uCanvas, vTexCoord);
    vec4 wetCenter    = texture(uWetMap, vTexCoord);

    if (uColorMixing == 0) {
        return centerCenter;
    }

    float wetness = wetCenter.r;
    if (wetness < 0.01) {
        return centerCenter; // Zona seca — sin cambios
    }

    vec2 texelSize = 1.0 / uCanvasSize;

    // Muestrear 8 vecinos (4 cardinales + 4 diagonales)
    vec4 neighbors[8];
    neighbors[0] = texture(uCanvas, vTexCoord + vec2(0.0, texelSize.y));  // Up
    neighbors[1] = texture(uCanvas, vTexCoord - vec2(0.0, texelSize.y));  // Down
    neighbors[2] = texture(uCanvas, vTexCoord - vec2(texelSize.x, 0.0));  // Left
    neighbors[3] = texture(uCanvas, vTexCoord + vec2(texelSize.x, 0.0));  // Right
    
    // Diagonales (peso espacial amortiguado por distancia 1/sqrt(2) = 0.707)
    neighbors[4] = texture(uCanvas, vTexCoord + vec2(-texelSize.x,  texelSize.y) * 0.707); // Up-Left
    neighbors[5] = texture(uCanvas, vTexCoord + vec2( texelSize.x,  texelSize.y) * 0.707); // Up-Right
    neighbors[6] = texture(uCanvas, vTexCoord + vec2(-texelSize.x, -texelSize.y) * 0.707); // Down-Left
    neighbors[7] = texture(uCanvas, vTexCoord + vec2( texelSize.x, -texelSize.y) * 0.707); // Down-Right

    // Ampliación del kernel del wetmap para detectar bordes con mayor claridad
    vec2 offsetDist = texelSize * 2.5;
    vec4 wetNeighbors[8];
    wetNeighbors[0] = texture(uWetMap, vTexCoord + vec2(0.0, offsetDist.y));
    wetNeighbors[1] = texture(uWetMap, vTexCoord - vec2(0.0, offsetDist.y));
    wetNeighbors[2] = texture(uWetMap, vTexCoord - vec2(offsetDist.x, 0.0));
    wetNeighbors[3] = texture(uWetMap, vTexCoord + vec2(offsetDist.x, 0.0));
    
    wetNeighbors[4] = texture(uWetMap, vTexCoord + vec2(-offsetDist.x,  offsetDist.y) * 0.707);
    wetNeighbors[5] = texture(uWetMap, vTexCoord + vec2( offsetDist.x,  offsetDist.y) * 0.707);
    wetNeighbors[6] = texture(uWetMap, vTexCoord + vec2(-offsetDist.x, -offsetDist.y) * 0.707);
    wetNeighbors[7] = texture(uWetMap, vTexCoord + vec2( offsetDist.x, -offsetDist.y) * 0.707);

    // ── GRANO DE PAPEL (textura de grano del papel) ──
    float paperGrain = 0.5; // Valor neutro
    if (uGrainIntensity > 0.001) {
        paperGrain = getGrainValue(getGlobalCoord(vTexCoord));
    }

    // 1. Simulación de difusión de pigmento (Paso 2 del algoritmo)
    // El pigmento tiende a fluir hacia donde hay más agua, pesado por humedad
    float totalWet = 0.0;
    vec3 blendedRGB = vec3(0.0);
    float blendedA = 0.0;

    // Pesos: cardinal = 1.0, diagonal = 0.707
    float weights[8];
    weights[0] = weights[1] = weights[2] = weights[3] = 1.0;
    weights[4] = weights[5] = weights[6] = weights[7] = 0.707;

    // CAPILARIDAD ANISÓTROPA DIRECCIONAL (FIBRAS DEL PAPEL 3D):
    // El pigmento viaja preferentemente a lo largo de los canales capilares (grano similar)
    // y encuentra gran resistencia al intentar subir crestas o barreras de fibra.
    if (uGrainIntensity > 0.01) {
        float neighborGrains[8];
        // Muestrear el grano solo en los 4 vecinos cardinales y aproximar las
        // diagonales como promedio de los cardinales adyacentes: ahorra 4
        // fetches de textura por píxel por tick con diferencia visual nula.
        vec2 ts = texelSize;
        neighborGrains[0] = getGrainValue(getGlobalCoord(vTexCoord + vec2(0.0, ts.y)));
        neighborGrains[1] = getGrainValue(getGlobalCoord(vTexCoord - vec2(0.0, ts.y)));
        neighborGrains[2] = getGrainValue(getGlobalCoord(vTexCoord - vec2(ts.x, 0.0)));
        neighborGrains[3] = getGrainValue(getGlobalCoord(vTexCoord + vec2(ts.x, 0.0)));

        neighborGrains[4] = (neighborGrains[0] + neighborGrains[2]) * 0.5; // Up-Left
        neighborGrains[5] = (neighborGrains[0] + neighborGrains[3]) * 0.5; // Up-Right
        neighborGrains[6] = (neighborGrains[1] + neighborGrains[2]) * 0.5; // Down-Left
        neighborGrains[7] = (neighborGrains[1] + neighborGrains[3]) * 0.5; // Down-Right

        for (int i = 0; i < 8; i++) {
            // Conductividad basada en similitud capilar (diferencia de grano absoluta)
            // A menor diferencia, el canal está más conectado
            float diff = abs(paperGrain - neighborGrains[i]);
            float capilarity = exp(-diff * 7.5); // Atenuación exponencial de conductividad
            weights[i] *= capilarity;
        }
    }

    for (int i = 0; i < 8; i++) {
        float wWet = wetNeighbors[i].r * weights[i];
        if (wWet > 0.001) {
            vec4 s = neighbors[i];
            vec3 sr = s.a > 0.001 ? s.rgb / s.a : vec3(0.0);
            blendedRGB += sr * wWet;
            blendedA += s.a * wWet;
            totalWet += wWet;
        }
    }

    vec3 avgPigment;
    float avgAlpha;
    if (totalWet > 0.001) {
        avgPigment = blendedRGB / totalWet;
        avgAlpha = blendedA / totalWet;
    } else {
        avgPigment = centerCenter.a > 0.001 ? centerCenter.rgb / centerCenter.a : vec3(0.0);
        avgAlpha = centerCenter.a;
    }

    // Rugosidad del papel (paperGrain) actúa como un obstáculo para la difusión del pigmento (flowResistance)
    float flowResistance = paperGrain * uGrainIntensity * 0.5;
    
    // Tasa de difusión escalada por el sangrado (uBleed) y la frescura del agua (1.0 - edad)
    float localPaintAmount = uPaintAmount * 0.6;
    float blendModulation = clamp((1.0 - localPaintAmount) * 2.0 + uColorStretch * 2.0, 0.0, 2.0);
    float diffusionRate = uBleed * (1.0 - wetCenter.g);
    float effectiveRate = clamp(diffusionRate * blendModulation * (1.0 - flowResistance), 0.0, 1.0);

    vec3 centerRGB_unp = centerCenter.a > 0.001 ? centerCenter.rgb / centerCenter.a : vec3(0.0);

    // Mezcla realista de pigmentos estilo Kubelka-Munk
    vec3 newPigment = mixKubelkaMunk(centerRGB_unp, avgPigment, effectiveRate);
    float newAlpha  = mix(centerCenter.a, avgAlpha, effectiveRate);

    // Gradiente de agua: alto en el perímetro del charco, ~0 en el interior
    float waterGradient = length(vec2(wetNeighbors[3].r - wetNeighbors[2].r, wetNeighbors[0].r - wetNeighbors[1].r));

    // 2. AGUADA — MIGRACIÓN INTERIOR→PERÍMETRO:
    // Por capilaridad, el agua arrastra el pigmento desde el interior del
    // charco hacia su borde. El interior (gradiente bajo, agua alta) pierde
    // densidad gradualmente mientras el agua está fresca → el centro queda
    // suave y translúcido; el anillo exterior la acumula (efecto de abajo).
    float freshness = 1.0 - wetCenter.g;
    if (uEdgeDarkening > 0.01 && freshness > 0.05) {
        float interior = wetness * (1.0 - clamp(waterGradient * 8.0, 0.0, 1.0));
        float depletion = interior * freshness * clamp(uBleed + 0.2, 0.0, 1.0) * 0.030;
        newAlpha *= (1.0 - depletion);
    }

    // 3. Granulación tridimensional, modulada por el agua: cuanta más agua
    // hay en el píxel, más sedimenta el pigmento en los poros. Además de la
    // densidad (alpha), el pigmento asentado oscurece sutilmente el TONO en
    // los valles, rompiendo la uniformidad del color digital.
    if (uGranulation > 0.01 && uGrainIntensity > 0.01) {
        float settle = 0.5 + 0.5 * wetness;  // El agua intensifica la sedimentación
        float granulationFactor = mix(1.0 + uGranulation * 0.40 * settle,
                                      1.0 - uGranulation * 0.25 * settle,
                                      paperGrain);
        newAlpha = clamp(newAlpha * granulationFactor, 0.0, 1.0);
        newPigment *= 1.0 - uGranulation * (1.0 - paperGrain) * wetness * 0.10;
    }

    // 4. Anillo perimetral de acumulación (Watercolor Fringe / Tide-mark)
    // El pigmento se asienta donde el gradiente de agua cae drásticamente.
    // — La banda smoothstep crea un anillo definido con transición suave
    //   hacia el interior (no un escalón rígido).
    // — Se intensifica al envejecer el agua (wetCenter.g → 1): el cerco
    //   aparece progresivamente durante el secado, como en papel real.
    // — El grano del papel perturba su intensidad → contorno orgánico.
    if (waterGradient > 0.012 && wetness > 0.02 && uEdgeDarkening > 0.01) {
        float dryingBoost = 0.55 + 0.9 * wetCenter.g;
        float rim = smoothstep(0.012, 0.14, waterGradient);
        float organic = mix(1.0, 0.6 + 0.8 * paperGrain,
                            min(uGrainIntensity * 1.5, 1.0));
        float fringeFactor = rim * 2.0 * uEdgeDarkening * dryingBoost * organic;
        newPigment *= (1.0 - clamp(fringeFactor * 0.60, 0.0, 0.85)); // Acumulación profunda de pigmento
        newAlpha = min(newAlpha * (1.0 + fringeFactor * 1.4), 1.0);  // Borde saturado y definido
    }

    // Devolver color premultiplicado para compositing correcto en FBO
    return clamp(vec4(newPigment * newAlpha, newAlpha), 0.0, 1.0);
}

// ============================================================================
// MODO 2: DRY STEP — Difusión de agua y evaporación progresiva
// ============================================================================
// Realiza dos operaciones sobre el mapa de humedad (uWetMap):
//   1. El agua fluye/se suaviza a los vecinos menos húmedos (difusión).
//   2. El agua se evapora gradualmente según la velocidad de secado.
// ============================================================================
vec4 dryStep() {
    vec4 centerWet = texture(uWetMap, vTexCoord);
    float wetness = centerWet.r;
    float secAge  = centerWet.g;

    if (wetness < 0.001) {
        return vec4(0.0, 0.0, 0.0, 1.0); // Ya completamente seco
    }

    vec2 texelSize = 1.0 / uCanvasSize;
    float upWet    = texture(uWetMap, vTexCoord + vec2(0.0, texelSize.y)).r;
    float downWet  = texture(uWetMap, vTexCoord - vec2(0.0, texelSize.y)).r;
    float leftWet  = texture(uWetMap, vTexCoord - vec2(texelSize.x, 0.0)).r;
    float rightWet = texture(uWetMap, vTexCoord + vec2(texelSize.x, 0.0)).r;

    // ── GRANO DE PAPEL ──
    float paperGrain = 0.5; // Valor neutro
    if (uGrainIntensity > 0.001) {
        paperGrain = getGrainValue(getGlobalCoord(vTexCoord));
    }

    // 1. Simulación de flujo de agua (Paso 1 del algoritmo: Promedio de humedad vecina)
    float avgWater = (upWet + downWet + leftWet + rightWet) / 4.0;

    // CAPILARIDAD ANISÓTROPA DIRECCIONAL (FIBRAS DEL PAPEL 3D):
    // El agua fluye preferentemente a lo largo de canales con grano de papel similar.
    if (uGrainIntensity > 0.01) {
        float upGrain    = getGrainValue(getGlobalCoord(vTexCoord + vec2(0.0, texelSize.y)));
        float downGrain  = getGrainValue(getGlobalCoord(vTexCoord - vec2(0.0, texelSize.y)));
        float leftGrain  = getGrainValue(getGlobalCoord(vTexCoord - vec2(texelSize.x, 0.0)));
        float rightGrain = getGrainValue(getGlobalCoord(vTexCoord + vec2(texelSize.x, 0.0)));

        float wUp    = exp(-abs(paperGrain - upGrain) * 7.5);
        float wDown  = exp(-abs(paperGrain - downGrain) * 7.5);
        float wLeft  = exp(-abs(paperGrain - leftGrain) * 7.5);
        float wRight = exp(-abs(paperGrain - rightGrain) * 7.5);

        float totalW = wUp + wDown + wLeft + wRight;
        if (totalW > 0.01) {
            avgWater = (upWet * wUp + downWet * wDown + leftWet * wLeft + rightWet * wRight) / totalW;
        }
    }
    
    // Suavizado/difusión de la humedad
    float newWetness = mix(wetness, avgWater, uBleed * 0.25);

    // 2. Evaporación + absorción (secado progresivo del charco)
    // Evaporación al aire según dryingRate (cada frame dura 80ms → factor 0.08)
    // más el agua que el papel absorbe hacia las fibras (uAbsorption).
    // Modulado por la porosidad tridimensional: las crestas (paperGrain alto)
    // secan rápido, los valles retienen el agua más tiempo.
    float grainEvaporationFactor = mix(0.5, 1.5, paperGrain);
    float evaporation = 0.08 * (uDryingRate + uAbsorption * 0.5) * grainEvaporationFactor;

    // Los bordes exteriores secan más rápido, y de forma IRREGULAR según el
    // grano del papel: las crestas del perímetro pierden el agua antes que
    // los poros, de modo que el contorno final del lavado retrocede de forma
    // orgánica (no como un círculo perfecto que encoge).
    float minNeighbor = min(min(upWet, downWet), min(leftWet, rightWet));
    float borderness = smoothstep(0.05, 0.25, wetness - minNeighbor);
    float borderMult = 1.0 + borderness * (0.6 + 1.2 * paperGrain);

    newWetness = max(0.0, newWetness - evaporation * borderMult);

    // Avanzar la edad del pigmento húmedo
    float newAge = min(1.0, secAge + evaporation * borderMult * 0.5);

    return vec4(newWetness, newAge, 0.0, 1.0);
}

// ============================================================================
// MAIN
// ============================================================================
void main() {
    if (uMode == 0) {
        fragColor = paintDab();
    } else if (uMode == 1) {
        fragColor = spreadWet();
    } else if (uMode == 2) {
        fragColor = dryStep();
    } else {
        // Modo desconocido — passthrough
        fragColor = texture(uCanvas, vTexCoord);
    }
}
