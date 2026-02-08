#version 330 core
in vec2 TexCoords;
out vec4 FragColor;

uniform vec4 color;           // Color del pincel (r, g, b, a)
uniform float hardness;       // 0.0 (suave) a 1.0 (duro)
uniform float pressure;       // Presión de la tableta (0.0 a 1.0)
uniform int brushType;        // 0=Redondo, 1=Lápiz, 2=Aerógrafo...

// Función de Ruido para textura de papel/lápiz
float noise(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main() {
    // Distancia del píxel al centro (0.0 centro, 0.5 borde)
    float dist = distance(TexCoords, vec2(0.5));
    
    // Recorte circular perfecto
    if (dist > 0.5) discard;

    float alpha = 0.0;
    
    // --- LÓGICA DE PINCELES ---
    
    if (brushType == 1) { 
        // LÁPIZ: Ruido granulado + Borde duro
        float grain = noise(TexCoords * 100.0) * 0.5; // Grano fino
        // El lápiz nunca es 100% opaco, depende mucho de la presión
        alpha = (1.0 - smoothstep(0.45, 0.5, dist)) * (0.5 + grain);
        alpha *= pressure; 
    } 
    else if (brushType == 2) { 
        // AERÓGRAFO: Caída cuadrática ultra suave
        // Invertimos dist para que 0.5 sea 0 y 0.0 sea 1
        float d = 1.0 - (dist * 2.0); 
        alpha = d * d * d; // Cúbica para máxima suavidad
    }
    else { 
        // REDONDO / TINTA (Por defecto)
        // Antialiasing matemático (Suavizado de bordes)
        // Cuanto más duro, menos "blur" en el borde (0.5)
        float edgeBlur = (1.0 - hardness) * 0.25 + 0.01; 
        alpha = 1.0 - smoothstep(0.5 - edgeBlur, 0.5, dist);
    }

    // Renderizado final
    FragColor = vec4(color.rgb, color.a * alpha);
}
