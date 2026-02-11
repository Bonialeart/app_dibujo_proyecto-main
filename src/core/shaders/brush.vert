#version 330 core
layout(location = 0) in vec3 position; // x, y, pressure

uniform mat4 projectionMatrix;
uniform float brushSize;

out float vPressure;

void main() {
    gl_Position = projectionMatrix * vec4(position.xy, 0.0, 1.0);
    
    // CORRECCIÓN: Usamos brushSize directamente. 
    // El motor ya calculó el tamaño con la presión.
    gl_PointSize = brushSize; 
    
    vPressure = position.z;
}
