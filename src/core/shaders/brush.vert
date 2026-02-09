#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aTexCoords;

out vec2 TexCoords;
out vec2 vWorldPos;
out vec2 vCanvasUV; // <--- NUEVO: Coordenada UV global

uniform mat4 model;
uniform mat4 projection;
uniform vec2 canvasSize; // <--- NUEVO: Tamaño lienzo

void main() {
    TexCoords = aTexCoords;
    gl_Position = projection * model * vec4(aPos, 0.0, 1.0);
    
    vec4 worldPos4 = model * vec4(aPos, 0.0, 1.0);
    vWorldPos = worldPos4.xy;
    
    // Normalizar a 0.0 - 1.0 para muestreo de canvasTexture
    // Asumimos que worldPos está en píxeles del lienzo
    vCanvasUV = vWorldPos / canvasSize;
}
