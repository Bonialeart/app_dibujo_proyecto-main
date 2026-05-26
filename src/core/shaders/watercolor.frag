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

// Mezcla de colores estilo Kubelka-Munk (más realista que interpolación lineal)
// Simula cómo los pigmentos físicos mezclan sus reflexiones
vec3 mixKubelkaMunk(vec3 colorA, vec3 colorB, float t) {
    // Transformar a espacio KM (k/s ratio)
    vec3 kmA = (1.0 - colorA) * (1.0 - colorA) / max(2.0 * colorA, vec3(0.001));
    vec3 kmB = (1.0 - colorB) * (1.0 - colorB) / max(2.0 * colorB, vec3(0.001));
    vec3 kmMix = mix(kmA, kmB, t);
    // Volver al espacio RGB
    return 1.0 + kmMix - sqrt(kmMix * kmMix + 2.0 * kmMix);
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

// Luminancia perceptual
float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Muestreo con offset en píxeles
vec4 sampleOffset(sampler2D tex, vec2 uv, vec2 offsetPx) {
    return texture(tex, uv + offsetPx / uCanvasSize);
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

    float dabAlpha    = dabSample.a * uFlow * uPressure;
    float localWet    = wetSample.r;   // Humedad preexistente en este pixel
    float secAge      = wetSample.g;   // Edad del pigmento húmedo (0=fresco 1=viejo)

    // ── GRANO DE PAPEL ──
    float grain = 1.0;
    if (uGrainIntensity > 0.001) {
        vec4 grainSamp = texture(uGrainTexture, vTexCoord * 4.0);
        float gv = dot(grainSamp.rgb, vec3(0.299, 0.587, 0.114));
        grain = mix(1.0, gv, uGrainIntensity);
    }
    dabAlpha *= grain;

    // ── DILUCIÓN: el agua diluye el pigmento del pincel ──
    // Mayor dilución = pigmento más transparente pero mayor depósito de agua
    float effectivePigment = (uBlendOnly == 1) ? 1.0 : (uPigment * (1.0 - uDilution * 0.7));
    dabAlpha *= effectivePigment;

    if (dabAlpha < 0.001) {
        // Sin cobertura de pincel — solo actualizar el mapa de humedad
        // Depositar humedad del pincel incluso sin pigmento
        float newWetness = localWet;
        if (uWetness > 0.01) {
            newWetness = max(localWet, uWetness * uFlow * uPressure * grain);
        }
        // Devolver canvas sin cambios (el wetmap lo gestiona el C++)
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

    // ── GRANULACIÓN: los pigmentos se aglomeran según la textura del papel ──
    if (uGranulation > 0.01 && uGrainIntensity > 0.001) {
        vec4 grainSamp = texture(uGrainTexture, vTexCoord * 6.0);
        float gv = dot(grainSamp.rgb, vec3(0.299, 0.587, 0.114));
        // En valles del papel (gv bajo) se concentra más el pigmento
        float granFactor = 1.0 + uGranulation * (0.5 - gv) * 2.0;
        dabAlpha = clamp(dabAlpha * granFactor, 0.0, 1.0);
    }

    // ── INTERACCIÓN WET-ON-WET ──
    // Si la zona ya está húmeda, el nuevo pigmento se funde con el existente
    vec3 finalRGB = brushRGB;
    float finalAlpha = dabAlpha;

    if (canvasSample.a > 0.001) {
        // Despremutiplicar color del canvas
        vec3 canvasRGB = canvasSample.rgb / canvasSample.a;

        if (localWet > 0.05) {
            // ━━━ ÁREA HÚMEDA: Wet-on-wet ━━━
            // Los colores se fusionan físicamente (Kubelka-Munk)
            // La frescura del agua determina cuánto se mezclan
            float freshness = 1.0 - secAge;               // 1=reciente, 0=viejo
            float blendFactor = localWet * freshness * 0.8;

            // Mezcla física de pigmentos
            vec3 mixedRGB = mixKubelkaMunk(brushRGB, canvasRGB, blendFactor);
            
            if (uBlendOnly == 1) {
                finalRGB = mixedRGB;
            } else {
                finalRGB = layerKubelkaMunk(mixedRGB, brushRGB, uPressure * 0.40);
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
                finalRGB = layerKubelkaMunk(canvasRGB, brushRGB, accumulation);

                // En zonas secas, la opacidad se acumula también (se oscurece)
                float blendToMultiply = (1.0 - uDilution * 0.5) * uPressure;
                float extraAlpha = canvasSample.a * blendToMultiply * 0.55;
                finalAlpha = min(finalAlpha + extraAlpha, 1.0);
            }
        }
    }

    // ── COMPOSICIÓN FINAL ──
    // Premultiply alpha para compositing correcto
    float outAlpha = canvasSample.a + finalAlpha * (1.0 - canvasSample.a);
    vec3 outRGB;

    if (outAlpha > 0.001) {
        // Porter-Duff Source-Over (premultiplied)
        vec3 srcPre = finalRGB * finalAlpha;
        vec3 dstPre = canvasSample.rgb;  // ya está premultiplicado en el buffer
        outRGB = srcPre + dstPre * (1.0 - finalAlpha);
    } else {
        outRGB = vec3(0.0);
    }

    return vec4(outRGB, outAlpha);
}

// ============================================================================
// MODO 1: SPREAD WET — Difusión del pigmento en zonas húmedas
// ============================================================================
// Simula la difusión física del pigmento que fluye y se expande con el agua,
// limitada por la fricción/resistencia de la textura rugosa del papel (grain).
// También genera tide-marks (fringing) en las fronteras húmedo/seco.
// ============================================================================
vec4 spreadWet() {
    vec4 centerCenter = texture(uCanvas, vTexCoord);
    vec4 wetCenter    = texture(uWetMap, vTexCoord);

    float wetness = wetCenter.r;
    if (wetness < 0.01) {
        return centerCenter; // Zona seca — sin cambios
    }

    vec2 texelSize = 1.0 / uCanvasSize;

    // Muestrear vecinos en cruz
    vec4 upCanvas    = texture(uCanvas, vTexCoord + vec2(0.0, texelSize.y));
    vec4 downCanvas  = texture(uCanvas, vTexCoord - vec2(0.0, texelSize.y));
    vec4 leftCanvas  = texture(uCanvas, vTexCoord - vec2(texelSize.x, 0.0));
    vec4 rightCanvas = texture(uCanvas, vTexCoord + vec2(texelSize.x, 0.0));

    vec4 upWet    = texture(uWetMap, vTexCoord + vec2(0.0, texelSize.y));
    vec4 downWet  = texture(uWetMap, vTexCoord - vec2(0.0, texelSize.y));
    vec4 leftWet  = texture(uWetMap, vTexCoord - vec2(texelSize.x, 0.0));
    vec4 rightWet = texture(uWetMap, vTexCoord + vec2(texelSize.x, 0.0));

    // ── GRANO DE PAPEL (textura de grano del papel) ──
    float paperGrain = 0.5; // Valor neutro
    if (uGrainIntensity > 0.001) {
        vec4 grainSamp = texture(uGrainTexture, vTexCoord * 5.0);
        paperGrain = dot(grainSamp.rgb, vec3(0.299, 0.587, 0.114));
    }

    // 1. Simulación de difusión de pigmento (Paso 2 del algoritmo)
    // El pigmento tiende a fluir hacia donde hay más agua, pesado por humedad
    float totalWet = upWet.r + downWet.r + leftWet.r + rightWet.r + 0.001;

    // Despremutiplicar colores vecinos para mezclar colores reales de pigmento
    vec3 upRGB    = upCanvas.a > 0.001 ? upCanvas.rgb / upCanvas.a : vec3(0.0);
    vec3 downRGB  = downCanvas.a > 0.001 ? downCanvas.rgb / downCanvas.a : vec3(0.0);
    vec3 leftRGB  = leftCanvas.a > 0.001 ? leftCanvas.rgb / leftCanvas.a : vec3(0.0);
    vec3 rightRGB = rightCanvas.a > 0.001 ? rightCanvas.rgb / rightCanvas.a : vec3(0.0);

    vec3 avgPigment = (upRGB * upWet.r + downRGB * downWet.r + leftRGB * leftWet.r + rightRGB * rightWet.r) / totalWet;
    float avgAlpha  = (upCanvas.a * upWet.r + downCanvas.a * downWet.r + leftCanvas.a * leftWet.r + rightCanvas.a * rightWet.r) / totalWet;

    // Rugosidad del papel (paperGrain) actúa como un obstáculo para la difusión del pigmento (flowResistance)
    float flowResistance = paperGrain * uGrainIntensity * 0.5;
    
    // Tasa de difusión escalada por el sangrado (uBleed) y la frescura del agua (1.0 - edad)
    float diffusionRate = uBleed * (1.0 - wetCenter.g);
    float effectiveRate = clamp(diffusionRate * (1.0 - flowResistance), 0.0, 1.0);

    vec3 centerRGB_unp = centerCenter.a > 0.001 ? centerCenter.rgb / centerCenter.a : vec3(0.0);

    // Mezcla realista de pigmentos estilo Kubelka-Munk
    vec3 newPigment = mixKubelkaMunk(centerRGB_unp, avgPigment, effectiveRate);
    float newAlpha  = mix(centerCenter.a, avgAlpha, effectiveRate);

    // 2. Efecto de borde de acumulación (Watercolor Fringe / Tide-mark) (Paso 3 del algoritmo)
    // El pigmento se acumula donde el gradiente de agua cae drásticamente (el borde del charco)
    float waterGradient = length(vec2(rightWet.r - leftWet.r, upWet.r - downWet.r));
    if (waterGradient > 0.05 && wetness > 0.02 && uEdgeDarkening > 0.01) {
        float fringeFactor = waterGradient * 0.20 * uEdgeDarkening;
        newPigment *= (1.0 - fringeFactor * 0.5); // Oscurece el color (el pigmento se acumula)
        newAlpha = min(newAlpha * (1.0 + fringeFactor), 1.0); // Aumenta la opacidad/densidad
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

    // 1. Simulación de flujo de agua (Paso 1 del algoritmo: Promedio de humedad vecina)
    float avgWater = (upWet + downWet + leftWet + rightWet) / 4.0;
    
    // Suavizado/difusión de la humedad
    float newWetness = mix(wetness, avgWater, uBleed * 0.25);

    // 2. Evaporación (Secado progresivo del charco)
    // Se evapora alrededor de un 2% base por ciclo, escalado por dryingRate y absorción
    float evaporation = 0.02 * uDryingRate * uAbsorption;

    // Los bordes exteriores secan más rápido
    float minNeighbor = min(min(upWet, downWet), min(leftWet, rightWet));
    float borderMult = (wetness - minNeighbor) > 0.15 ? 1.8 : 1.0;

    newWetness = newWetness * (1.0 - evaporation * borderMult);
    newWetness = max(0.0, newWetness);

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
