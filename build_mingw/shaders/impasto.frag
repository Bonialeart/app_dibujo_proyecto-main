#version 330 core

in vec2 TexCoords;
out vec4 FragColor;

uniform sampler2D canvasTexture; // Contains Color in RGB and Accumulated Height in Alpha
uniform vec2 screenSize;         
uniform float reliefStrength;    
uniform vec3 lightPos;           
uniform float impastoShininess; 

const float SPECULAR_INTENSITY = 0.5;

void main()
{
    vec4 samplePoint = texture(canvasTexture, TexCoords);
    vec3 baseColor = samplePoint.rgb;
    float heightC = samplePoint.a; // REAL ACCUMULATED HEIGHT

    // If no height/paint, no lighting
    if (heightC < 0.001) {
        // Output unchanged color for dry areas
        FragColor = vec4(baseColor, samplePoint.a); // Actually a=0 here
        return;
    }

    // --- 1. HIGH-QUALITY NORMAL MAPPING (Sobel Operator) ---
    vec2 texelSize = 1.0 / screenSize;
    
    // Sample height neighbors
    float hL = texture(canvasTexture, TexCoords + vec2(-texelSize.x, 0.0)).a;
    float hR = texture(canvasTexture, TexCoords + vec2(texelSize.x, 0.0)).a;
    float hT = texture(canvasTexture, TexCoords + vec2(0.0, -texelSize.y)).a;
    float hB = texture(canvasTexture, TexCoords + vec2(0.0, texelSize.y)).a;
    
    // Sobel gradient (Z is 'up')
    float gx = (hR - hL) * reliefStrength;
    float gy = (hB - hT) * reliefStrength;
    
    // Low reliefStrength means normal is (0,0,1)
    vec3 normal = normalize(vec3(-gx, -gy, 0.5));

    // --- 2. LIGHTING (Phong-Blinn) ---
    vec3 lightDir = normalize(lightPos);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 halfDir = normalize(lightDir + viewDir);

    float diff = max(dot(normal, lightDir), 0.0);
    float spec = pow(max(dot(normal, halfDir), 0.0), impastoShininess);

    // Ambient Occlusion emulation (valleys are darker)
    // Compare center height to average neighborhood
    float hAvg = (hL + hR + hT + hB) * 0.25;
    float ao = clamp(1.0 + (heightC - hAvg) * 2.0, 0.6, 1.1);

    // --- 3. COMPOSITION ---
    // If baseColor is premultiplied, we need and un-premultiply version for lighting?
    // Actually, we can just apply lighting as a multiplier.
    
    vec3 ambient = baseColor * 0.3 * ao;
    vec3 diffuse = baseColor * diff * 0.7;
    vec3 specular = vec3(1.0) * spec * SPECULAR_INTENSITY * (0.5 + 0.5 * heightC);

    FragColor = vec4(ambient + diffuse + specular, 1.0);
}
