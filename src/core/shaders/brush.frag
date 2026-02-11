#version 330 core

in vec2 TexCoords;
out vec4 FragColor;

uniform vec4 color;
uniform float pressure;
uniform float hardness;
uniform int brushType;

// Texturas (para compatibilidad con el renderer aunque no las usemos todas aun)
uniform sampler2D brushTexture;
uniform int uHasTexture;

void main() {
    // 1. Forma básica: Círculo suave
    float dist = distance(TexCoords, vec2(0.5));
    float softAlpha = 1.0 - smoothstep(hardness * 0.4, 0.5, dist);
    
    // 2. Si tiene textura, la multiplicamos
    if (uHasTexture == 1) {
        vec4 texSample = texture(brushTexture, TexCoords);
        // Usamos el alpha o el r (si es escala de grises)
        float texAlpha = max(texSample.a, texSample.r);
        softAlpha *= texAlpha;
    }

    // 3. Resultado final
    float finalAlpha = color.a * softAlpha * pressure;
    
    // Evitamos el 'discard' para mayor estabilidad
    if (dist > 0.5) finalAlpha = 0.0;
    
    FragColor = vec4(color.rgb, finalAlpha);
}
