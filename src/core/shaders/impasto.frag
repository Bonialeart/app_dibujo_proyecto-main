#version 330 core

in vec2 TexCoords;
in vec2 vCanvasUV; // Reusable from brush.vert
out vec4 FragColor;

uniform sampler2D canvasTexture; // La capa con tu dibujo
uniform vec2 screenSize;         // Tamaño del canvas en px
uniform float reliefStrength;    // Cuánto relieve quieres (ej: 5.0)
uniform vec3 lightPos;           // Posición de la luz (0.0 a 1.0)

uniform float impastoShininess; // Qué tan "húmedo" se ve (ej: 64.0)
const float SPECULAR_INTENSITY = 0.5;

// Función de ruido simple
float hash(vec2 p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main()
{
    vec4 baseColor = texture(canvasTexture, TexCoords);

    // Si no hay pintura, no procesamos luz
    if (baseColor.a < 0.01) {
        FragColor = baseColor;
        return;
    }

    // --- 1. CALCULAR LAS NORMALES ---
    // Altura base: Alpha
    float hCenter = baseColor.a;
    
    // Altura detalle: Ruido procesal (simula grano del lienzo/cerdas)
    float grainScale = 0.5; // Ajustar según resolución
    float nCenter = noise(TexCoords * screenSize * grainScale);
    
    // Altura detalle: Variación por color (Luminosidad) -> La pintura no es plana
    float lum = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    
    // Altura Total Combinada
    // Alpha pesa más para los bordes, el resto para textura interna
    float heightC = hCenter + (nCenter * 0.05) + (lum * 0.02);

    vec2 pixelStep = 1.0 / screenSize;
    
    // Muestreo Vecino (Derecha)
    vec4 cRight = texture(canvasTexture, TexCoords + vec2(pixelStep.x, 0.0));
    float hRight = cRight.a + (noise((TexCoords + vec2(pixelStep.x, 0.0)) * screenSize * grainScale) * 0.05) + (dot(cRight.rgb, vec3(0.299, 0.587, 0.114)) * 0.02);
    
    // Muestreo Vecino (Arriba)
    vec4 cTop = texture(canvasTexture, TexCoords + vec2(0.0, pixelStep.y));
    float hTop = cTop.a + (noise((TexCoords + vec2(0.0, pixelStep.y)) * screenSize * grainScale) * 0.05) + (dot(cTop.rgb, vec3(0.299, 0.587, 0.114)) * 0.02);

    float currentRelief = reliefStrength * 2.0; // Boost
    
    // Vector Normal
    vec3 normal = normalize(vec3(
        (heightC - hRight) * currentRelief, 
        (heightC - hTop) * currentRelief, 
        1.0 
    ));

    // --- 2. ILUMINACIÓN (Phong Model) ---
    vec3 lightDir = normalize(lightPos); 
    float diff = max(dot(normal, lightDir), 0.0);
    
    vec3 viewDir = vec3(0.0, 0.0, 1.0); 
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), impastoShininess);

    // --- 3. COMPOSICIÓN FINAL ---
    // Ambiente + Difusa + Especular
    // Sombreado propio para resaltar valles
    float ao = 1.0;
    if (heightC < hRight && heightC < hTop) ao = 0.8; // Oscurecer huecos

    vec3 ambient = baseColor.rgb * 0.6 * ao; 
    vec3 diffuse = baseColor.rgb * diff * 0.9;
    vec3 specular = vec3(1.0) * spec * SPECULAR_INTENSITY;

    FragColor = vec4(ambient + diffuse + specular, baseColor.a);
}
