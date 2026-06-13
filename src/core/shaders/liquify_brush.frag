// ArtFlow Studio — Liquify Brush Displacement Pass (GPU)
// Actualiza el mapa de desplazamiento acumulado para un solo dab del pincel
// usando ping-pong: lee el desplazamiento previo (uPrevDisp) y escribe el
// nuevo al FBO destino. Cada modo aplica su fórmula física con falloff
// smoothstep. Fuera del radio del pincel el desplazamiento pasa intacto,
// por lo que no se necesita blit previo entre ping y pong.
//
// Codificación (compatible con FBO RGBA16F o fallback RGBA8):
//   texel.rg = (D_px / uMaxDisp) * 0.5 + uDispZero
// uDispZero es el punto cero exacto del formato (0.5 en 16F, 128/255 en 8-bit)
// para que un mapa "sin deformación" decodifique exactamente a (0, 0).

#ifdef GL_ES
precision highp float;
#endif

varying vec2 vTexCoord;

uniform sampler2D uPrevDisp;   // desplazamiento acumulado (pase anterior)
uniform vec2  uCanvasSize;     // dimensiones del lienzo en px
uniform vec2  uCenter;         // centro del dab (px de lienzo, y hacia abajo)
uniform vec2  uPrevCenter;     // centro del dab anterior (px de lienzo)
uniform float uRadius;         // radio R del pincel (px)
uniform float uStrength;       // fuerza S (0..1)
uniform float uMorpher;        // suavidad del falloff (0 = duro, 1 = muy suave)
uniform float uMaxDisp;        // rango de normalización del desplazamiento (px)
uniform float uDispZero;       // punto cero exacto de la codificación
uniform int   uMode;           // LiquifyMode (0..8)

vec2 decodeDisp(vec4 t) {
    return (t.rg - uDispZero) * 2.0 * uMaxDisp;
}

vec4 encodeDisp(vec2 d) {
    vec2 n = clamp(d / uMaxDisp, vec2(-1.0), vec2(1.0));
    return vec4(n * 0.5 + uDispZero, 0.0, 1.0);
}

// Vector pseudoaleatorio constante por celda en [-1,1]^2 — facetas cristalinas
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453) * 2.0 - 1.0;
}

void main() {
    vec2 P = vTexCoord * uCanvasSize;
    vec2 D = decodeDisp(texture2D(uPrevDisp, vTexCoord));

    // Falloff suave (curva smoothstep) con control de suavidad (morpher)
    float dist = distance(P, uCenter);
    float t = 1.0 - clamp(dist / uRadius, 0.0, 1.0);
    float falloff = t * t * (3.0 - 2.0 * t);
    falloff = pow(falloff, mix(0.6, 2.5, uMorpher));

    if (falloff > 0.0) {
        float S = uStrength;
        vec2 V = uCenter - uPrevCenter; // dirección/velocidad del trazo (px)
        vec2 rel = P - uCenter;

        // El preview muestrea src(P - D), de modo que D apunta en la
        // dirección en que se MUEVE el contenido. Las constantes de tasa
        // mantienen el efecto controlable al acumularse un dab por evento.
        if (uMode == 0) {
            // Push — arrastra el contenido en la dirección del trazo
            D += V * S * falloff;
        } else if (uMode == 1 || uMode == 2) {
            // Twirl CW / CCW — rotación máxima en el centro
            float dir = (uMode == 1) ? 1.0 : -1.0;
            float theta = S * falloff * dir * 0.15;
            float c = cos(theta);
            float s = sin(theta);
            vec2 rotated = vec2(c * rel.x - s * rel.y, s * rel.x + c * rel.y);
            D += rotated - rel;
        } else if (uMode == 3) {
            // Pinch — contrae el contenido hacia el centro
            D += (uCenter - P) * S * falloff * 0.1;
        } else if (uMode == 4) {
            // Expand — infla el contenido hacia afuera (efecto lupa)
            D += (P - uCenter) * S * falloff * 0.1;
        } else if (uMode == 5) {
            // Crystals — perturbación fractal en facetas (~R/8 px por celda)
            float freq = 8.0 / max(uRadius, 1.0);
            vec2 N = hash22(floor(P * freq));
            D += N * S * falloff * uRadius * 0.1;
        } else if (uMode == 6) {
            // Edge — comprime perpendicular al trazo (afilar bordes/arrugas)
            float len = length(V);
            if (len > 0.001) {
                vec2 T = V / len;
                vec2 Nrm = vec2(-T.y, T.x);
                float side = sign(dot(rel, Nrm));
                D -= Nrm * side * S * falloff * 2.0;
            }
        } else if (uMode == 7) {
            // Reconstruct — restaura gradualmente el desplazamiento a cero
            D *= 1.0 - S * falloff * 0.5;
        } else if (uMode == 8) {
            // Smooth — relaja hacia el promedio de los 4 vecinos
            vec2 px = 1.0 / uCanvasSize;
            vec2 avg =
                decodeDisp(texture2D(uPrevDisp, vTexCoord + vec2(px.x, 0.0))) +
                decodeDisp(texture2D(uPrevDisp, vTexCoord - vec2(px.x, 0.0))) +
                decodeDisp(texture2D(uPrevDisp, vTexCoord + vec2(0.0, px.y))) +
                decodeDisp(texture2D(uPrevDisp, vTexCoord - vec2(0.0, px.y)));
            D = mix(D, avg * 0.25, S * falloff);
        }
    }

    gl_FragColor = encodeDisp(D);
}
