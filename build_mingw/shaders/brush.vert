#version 330 core
layout(location = 0) in vec2 position; // 0..1 local quad coordinates
layout(location = 1) in vec2 texCoords;
layout(location = 2) in vec2 instPos;
layout(location = 3) in float instSize;
layout(location = 4) in float instRot;
layout(location = 5) in vec4 instColor;

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform int instanced;

out vec2 TexCoords;
out vec4 vColor;
out vec2 vPos;
out float vSize;
out float vRot;

void main() {
    if (instanced == 1) {
        float cx = instPos.x - instSize / 2.0;
        float cy = instPos.y - instSize / 2.0;

        mat4 model = mat4(1.0);
        model[0][0] = instSize;
        model[1][1] = instSize;
        model[3][0] = cx;
        model[3][1] = cy;

        gl_Position = projectionMatrix * model * vec4(position, 0.0, 1.0);
        TexCoords = texCoords;
        vColor = instColor;
        vPos = instPos;
        vSize = instSize;
        vRot = instRot;
    } else {
        gl_Position = projectionMatrix * modelMatrix * vec4(position, 0.0, 1.0);
        TexCoords = texCoords;
    }
}
