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
    float effectivePigment = uPigment * (1.0 - uDilution * 0.7);
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

    // ── COLOR DEL PINCEL ──
    vec3 brushRGB = uBrushColor.rgb;

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
            finalRGB = mix(brushRGB, mixedRGB, blendFactor);

            // En zonas húmedas, el pigmento se expande (alpha mayor en bordes)
            // El Bleed controla cuánto se expande el borde mojado
            float spreadBoost = localWet * uBleed * 0.5;
            finalAlpha = min(finalAlpha + spreadBoost * 0.3, 1.0);

        } else {
            // ━━━ ÁREA SECA: Acumulación de pigmento ━━━
            // Pintar sobre zona seca OSCURECE (como en acuarela real)
            // Implementado como Multiply blend del pigmento nuevo sobre el existente
            float accumulation = (1.0 - uDilution * 0.5);
            vec3 multiplyResult = brushRGB * canvasRGB;
            // Mayor acumulación de pigmento donde la presión es alta
            float blendToMultiply = accumulation * uPressure;
            finalRGB = mix(brushRGB, multiplyResult, blendToMultiply * canvasSample.a);

            // En zonas secas, la opacidad se acumula también (se oscurece)
            float extraAlpha = canvasSample.a * blendToMultiply * 0.4;
            finalAlpha = min(finalAlpha + extraAlpha, 1.0);
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
// Cada cierto tiempo (controlado por CPU) se ejecuta esta pasada:
//   • En cada pixel húmedo, el pigmento "fluye" hacia los vecinos menos húmedos
//   • El tide-mark (borde oscuro) se forma en la frontera húmedo/seco
//   • El bloom ocurre cuando agua limpia rodea pigmento húmedo
// ============================================================================
vec4 spreadWet() {
    vec4 center    = texture(uCanvas, vTexCoord);
    vec4 wetCenter = texture(uWetMap, vTexCoord);

    float wetness = wetCenter.r;
    if (wetness < 0.01) {
        return center; // Zona seca — sin cambios
    }

    // Muestrear vecinos en las 8 direcciones (brújula) para detectar gradiente
    float step = 1.5; // En píxeles — mayor = más expansión pero menos detalle
    vec4 n  = sampleOffset(uCanvas, vTexCoord, vec2( 0,  step));
    vec4 s  = sampleOffset(uCanvas, vTexCoord, vec2( 0, -step));
    vec4 e  = sampleOffset(uCanvas, vTexCoord, vec2( step,  0));
    vec4 w  = sampleOffset(uCanvas, vTexCoord, vec2(-step,  0));
    vec4 ne = sampleOffset(uCanvas, vTexCoord, vec2( step,  step));
    vec4 nw = sampleOffset(uCanvas, vTexCoord, vec2(-step,  step));
    vec4 se = sampleOffset(uCanvas, vTexCoord, vec2( step, -step));
    vec4 sw = sampleOffset(uCanvas, vTexCoord, vec2(-step, -step));

    vec4 wn  = sampleOffset(uWetMap, vTexCoord, vec2( 0,  step));
    vec4 ws  = sampleOffset(uWetMap, vTexCoord, vec2( 0, -step));
    vec4 we  = sampleOffset(uWetMap, vTexCoord, vec2( step,  0));
    vec4 ww  = sampleOffset(uWetMap, vTexCoord, vec2(-step,  0));

    // Centro de masa del pigmento vecino (pesado por humedad)
    float totalWet = wn.r + ws.r + we.r + ww.r + 0.001;
    vec3 avgNeighborRGB = (n.rgb * wn.r + s.rgb * ws.r +
                           e.rgb * we.r + w.rgb * ww.r) / totalWet;
    float avgNeighborA = (n.a * wn.r + s.a * ws.r +
                          e.a * we.r + w.a * ww.r) / totalWet;

    // ── TIDE-MARK / BORDE DE SECADO ──
    // En la frontera húmedo/seco, el pigmento se concentra
    // Detectar si algún vecino está seco
    float minNeighborWet = min(min(wn.r, ws.r), min(we.r, ww.r));
    bool atDryBorder = (minNeighborWet < 0.08 && wetness > 0.1);

    // Cuánto fluye el pigmento hacia afuera
    float spreadStrength = wetness * uBleed * (1.0 - wetCenter.g);  // Más fresco = más expansión

    // Acumular pigmento recibido de vecinos más húmedos
    vec3 incomingRGB = vec3(0.0);
    float incomingA  = 0.0;

    // Cada vecino más húmedo "empuja" pigmento hacia este pixel
    float pushN = max(0.0, wn.r - wetness) * uBleed;
    float pushS = max(0.0, ws.r - wetness) * uBleed;
    float pushE = max(0.0, we.r - wetness) * uBleed;
    float pushW = max(0.0, ww.r - wetness) * uBleed;

    float totalPush = pushN + pushS + pushE + pushW;

    if (totalPush > 0.001) {
        incomingRGB = (n.rgb * pushN + s.rgb * pushS +
                       e.rgb * pushE + w.rgb * pushW) / totalPush;
        incomingA   = (n.a * pushN + s.a * pushS +
                       e.a * pushE + w.a * pushW) / totalPush;

        // Fusión del pigmento entrante con el existente
        float blend = clamp(totalPush * 0.3, 0.0, 0.5);
        vec3 centerRGB_unp = center.a > 0.001 ? center.rgb / center.a : vec3(1.0);
        vec3 incomRGB_unp  = incomingA > 0.001 ? incomingRGB / incomingA : vec3(1.0);

        vec3 blendedRGB = mixKubelkaMunk(centerRGB_unp, incomRGB_unp, blend);
        float blendedA  = center.a + incomingA * blend * (1.0 - center.a);

        center = vec4(blendedRGB * blendedA, blendedA);
    }

    // ── CONCENTRACIÓN EN BORDE (Tide-mark) ──
    // Cuando el borde está cerca de zona seca, concentrar el pigmento
    if (atDryBorder && uEdgeDarkening > 0.01) {
        // El pigmento se acumula físicamente en la frontera de tensión superficial
        float concentration = uEdgeDarkening * wetness * (1.0 - wetCenter.g);
        // Oscurecer RGB (más pigmento = más absorción de luz)
        vec3 centerRGB_unp = center.a > 0.001 ? center.rgb / center.a : vec3(1.0);
        centerRGB_unp = centerRGB_unp * (1.0 - concentration * 0.4);  // Oscurecer
        float extraA = center.a + concentration * 0.25 * (1.0 - center.a);
        center = vec4(centerRGB_unp * extraA, extraA);
    }

    // ── BACKRUN / BLOOM ──
    // Si hay agua limpia (baja densidad de pigmento) rodeando pigmento húmedo,
    // el agua "empuja" el pigmento hacia afuera creando el efecto bloom
    vec3 centerRGBnorm = center.a > 0.001 ? center.rgb / center.a : vec3(1.0);
    float centerLum = luminance(centerRGBnorm);
    float neighborLum = luminance(avgNeighborRGB.rgb / max(avgNeighborA, 0.001));

    if (neighborLum < centerLum - 0.1 && wetness > 0.3 && avgNeighborA < center.a * 0.6) {
        // El pigmento en el interior se separa hacia el borde (capillaridad)
        float bloom = (centerLum - neighborLum) * wetness * uBleed * 0.3;
        float newA = min(center.a + bloom * 0.15, 1.0);
        center = vec4(centerRGBnorm * newA, newA);
    }

    return clamp(center, 0.0, 1.0);
}

// ============================================================================
// MODO 2: DRY STEP — Avanzar el proceso de secado
// ============================================================================
// Esta pasada solo opera sobre el WetMap:
//   • La humedad disminuye con el tiempo y la absorción del papel
//   • En los bordes de la zona húmeda el secado es más rápido
//   • Devuelve el nuevo estado del WetMap en fragColor
// ============================================================================
vec4 dryStep() {
    vec4 wetSample = texture(uWetMap, vTexCoord);
    float wetness = wetSample.r;
    float secAge  = wetSample.g;

    if (wetness < 0.001) {
        return vec4(0.0, 0.0, 0.0, 1.0); // Ya seco
    }

    // Detectar si estamos en el borde (vecinos menos húmedos) — los bordes secan antes
    float wn = texture(uWetMap, vTexCoord + vec2(0,  1) / uCanvasSize).r;
    float ws = texture(uWetMap, vTexCoord + vec2(0, -1) / uCanvasSize).r;
    float we = texture(uWetMap, vTexCoord + vec2( 1, 0) / uCanvasSize).r;
    float ww = texture(uWetMap, vTexCoord + vec2(-1, 0) / uCanvasSize).r;
    float minNeighbor = min(min(wn, ws), min(we, ww));

    // Los bordes secan hasta 2x más rápido
    float borderMult = (wetness - minNeighbor) > 0.15 ? 1.8 : 1.0;

    // Evaporación base
    float dryAmount = uDryingRate * uAbsorption * borderMult * 0.016; // ~1 frame a 60fps

    float newWetness = max(0.0, wetness - dryAmount);
    float newAge     = min(1.0, secAge + dryAmount * 0.5); // El pigmento "envejece"

    // R=humedad actual, G=edad del pigmento, B=sin uso, A=1
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
