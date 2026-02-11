#version 330 core

in float vPressure;       
uniform vec4 color;       
uniform float hardness;   

out vec4 FragColor;

void main() {
    // Distancia desde el centro del punto
    float dist = length(gl_PointCoord - vec2(0.5));

    // Suavizado premium (sin usar 'discard' para evitar rayas horizontales)
    float mask = 1.0 - smoothstep(0.0, 0.5, dist);
    
    // Aplicamos la dureza para que el borde sea más o menos suave
    float softEdge = 1.0 - smoothstep(hardness * 0.5, 0.5, dist);

    // El Alpha final determina la fuerza del borrado/pincel
    float finalAlpha = color.a * softEdge * (vPressure > 0.0 ? vPressure : 1.0);

    // Si estamos fuera del radio del pincel, alpha es 0
    if (dist > 0.5) finalAlpha = 0.0;

    FragColor = vec4(color.rgb, finalAlpha);
}
