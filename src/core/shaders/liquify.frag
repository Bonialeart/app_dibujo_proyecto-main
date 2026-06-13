// ArtFlow Studio — Liquify Displacement Shader (preview / bake)
// Deforma la textura original aplicando el mapa de desplazamiento acumulado.
// GLSL portable: compila como GLSL 1.10 en escritorio y ES 1.00 en Android.
//
// Muestreo inverso: out(P) = src(P - D). El pase de pincel
// (liquify_brush.frag) acumula D en la dirección en que se mueve el
// contenido, así que aquí se resta para buscar el texel de origen.
//
// Uniforms:
//   uSource       – textura original de la capa (RGBA premultiplicado)
//   uDisplacement – mapa de desplazamiento (dx en R, dy en G, codificado)
//   uCanvasSize   – dimensiones del lienzo en píxeles
//   uOpacity      – opacidad del preview
//   uMaxDisp      – rango de normalización del desplazamiento (px)
//   uDispZero     – punto cero exacto de la codificación (0.5 ó 128/255)

#ifdef GL_ES
precision highp float;
#endif

varying vec2 vTexCoord;

uniform sampler2D uSource;
uniform sampler2D uDisplacement;
uniform vec2      uCanvasSize;
uniform float     uOpacity;
uniform float     uMaxDisp;
uniform float     uDispZero;

void main() {
    // Decodificar el desplazamiento: [0,1] → [-1,1] → píxeles → UV
    vec4 disp = texture2D(uDisplacement, vTexCoord);
    vec2 offsetPx = (disp.rg - uDispZero) * 2.0 * uMaxDisp;

    // Muestrear la fuente en la UV desplazada (interpolación GL_LINEAR
    // del hardware: la textura fuente debe tener filtrado lineal).
    vec2 sampleUV = vTexCoord - offsetPx / uCanvasSize;
    sampleUV = clamp(sampleUV, vec2(0.0), vec2(1.0));

    gl_FragColor = texture2D(uSource, sampleUV) * uOpacity;
}
