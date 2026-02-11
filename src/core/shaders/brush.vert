#version 330 core
layout(location = 0) in vec2 position; // 0..1 local quad coordinates
layout(location = 1) in vec2 texCoords;

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;

out vec2 TexCoords;

void main() {
    gl_Position = projectionMatrix * modelMatrix * vec4(position, 0.0, 1.0);
    TexCoords = texCoords;
}
