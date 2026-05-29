#version 330 core
in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D u_sdfFontTexture;
uniform vec4 u_textColor;
uniform vec4 u_outlineColor;
uniform float u_edge;           // SDF threshold (normally 0.5)
uniform float u_outlineWidth;   // Outline offset inside distance field (0.0 to 0.5)

void main() {
    // Sample the distance from the SDF texture atlas channel
    float distance = texture(u_sdfFontTexture, vTexCoord).r;
    
    // Partial derivative anti-aliasing for high density displays
    float width = fwidth(distance);
    float alpha = smoothstep(u_edge - width, u_edge + width, distance);
    
    // Outlined rendering pass
    if (u_outlineWidth > 0.0) {
        float outlineEdge = u_edge - u_outlineWidth;
        float outlineAlpha = smoothstep(outlineEdge - width, outlineEdge + width, distance);
        vec4 combinedColor = mix(u_outlineColor, u_textColor, alpha);
        fragColor = vec4(combinedColor.rgb, outlineAlpha * combinedColor.a);
    } else {
        fragColor = vec4(u_textColor.rgb, alpha * u_textColor.a);
    }
}
