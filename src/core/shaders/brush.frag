#version 330 core

in vec2 TexCoords;
in vec2 vWorldPos;
in vec2 vCanvasUV;

out vec4 FragColor;

uniform vec4 color;
uniform float pressure;
uniform float hardness;
uniform int brushType;

// Texturas
uniform sampler2D brushTexture;     // Forma del pincel (Dab)
uniform sampler2D canvasTexture;    // Capa actual (para mezclar)
uniform int uHasTexture;

// Propiedades Premium
uniform float textureScale;
uniform float textureIntensity;
uniform float wetness;
uniform float dilution;
uniform float smudge;

void main() {
    // 1. Calcular la forma básica del pincel (Sello circular suave)
    float dist = distance(TexCoords, vec2(0.5));
    float softAlpha = 1.0 - smoothstep(hardness * 0.5, 0.5, dist);
    
    // 2. Aplicar textura profesional (Grain / Paper Texture)
    float dabAlpha = softAlpha;
    if (uHasTexture == 1) {
        // Muestrear textura usando UVs de CANVAS para el grano de papel (efecto fijo)
        // y TexCoords para la forma de la punta del pincel
        vec4 brushSample = texture(brushTexture, TexCoords);
        
        // Efecto Grained: Multiplicar por el grano del lienzo en esa posición
        // Usamos textureScale para controlar la finura del papel
        vec4 grainSample = texture(brushTexture, vCanvasUV * textureScale);
        
        // Mezclar forma circular con grano de papel
        dabAlpha = softAlpha * mix(1.0, grainSample.r, textureIntensity);
        
        // Si la textura tiene forma (Alpha), aplicarla también
        if (brushSample.a > 0.01) {
            dabAlpha *= brushSample.a;
        } else {
             dabAlpha *= brushSample.r; // Fallback para texturas rojo/grayscale
        }
    }
    
    // 3. Lógica de Pincel Húmedo (Wet Mix / Smudge)
    vec4 finalColor = color;
    float finalAlpha = color.a * dabAlpha * pressure;
    
    // Pulir bordes para evitar "puntos fantasma"
    if (finalAlpha < 0.005) discard;
    
    FragColor = vec4(finalColor.rgb, finalAlpha);
}
