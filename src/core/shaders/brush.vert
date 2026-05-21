#version 330 core
layout(location = 0) in vec2 position; // 0..1 local quad coordinates
layout(location = 1) in vec2 texCoords;
layout(location = 2) in vec2 instPos;
layout(location = 3) in float instSize;
layout(location = 4) in float instRot;
layout(location = 5) in vec4 instColor;
layout(location = 6) in float instPaintLoad;

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform int instanced;
uniform float paintLoad;

out vec2 TexCoords;
out vec4 vColor;
out vec2 vPos;
out float vSize;
out float vRot;
out vec2 vWorldPos;
out float vPaintLoad;

void main() {
    if (instanced == 1) {
        float cs = cos(instRot);
        float sn = sin(instRot);

        // Quad position goes from 0..1. Center is 0.5, 0.5.
        vec2 localPos = position - vec2(0.5);
        
        // Scale
        localPos *= instSize;
        
        // Rotate
        vec2 rotatedPos;
        rotatedPos.x = localPos.x * cs - localPos.y * sn;
        rotatedPos.y = localPos.x * sn + localPos.y * cs;
        
        // Translate to instPos
        vec2 worldPos = rotatedPos + instPos;
        
        gl_Position = projectionMatrix * vec4(worldPos, 0.0, 1.0);
        TexCoords = texCoords;
        vColor = instColor;
        vPos = instPos;
        vSize = instSize;
        vRot = instRot;
        vWorldPos = worldPos;
        vPaintLoad = instPaintLoad;
    } else {
        vec4 worldPosVec = modelMatrix * vec4(position, 0.0, 1.0);
        gl_Position = projectionMatrix * worldPosVec;
        TexCoords = texCoords;
        vWorldPos = worldPosVec.xy;
        vPaintLoad = paintLoad;
    }
}
