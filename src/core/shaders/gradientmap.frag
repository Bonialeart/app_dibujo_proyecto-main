#version 330 core
in vec2 vTexCoord;
out vec4 fragColor;

uniform sampler2D uSource;
uniform int uPreset; // 0 = Sunset, 1 = Ocean, 2 = Forest, 3 = Retro, 4 = Manga

// Helper to linearly interpolate between three colors based on t (0.0 to 1.0)
vec3 getGradientColor(float t, vec3 c0, vec3 c1, vec3 c2) {
    if (t < 0.5) {
        return mix(c0, c1, t * 2.0);
    } else {
        return mix(c1, c2, (t - 0.5) * 2.0);
    }
}

void main() {
    vec4 srcColor = texture(uSource, vTexCoord);
    if (srcColor.a < 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Un-premultiply alpha to apply color mapping correctly, then re-multiply
    vec3 rgb = srcColor.rgb / srcColor.a;
    
    // Calculate luminance using standard weights
    float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
    luma = clamp(luma, 0.0, 1.0);
    
    vec3 mappedColor = vec3(0.0);
    
    if (uPreset == 0) {
        // Sunset: Deep purple -> Coral/Orange-Red -> Warm Peach/Yellow
        vec3 c0 = vec3(0.235, 0.106, 0.353); // #3c1b5a
        vec3 c1 = vec3(0.827, 0.282, 0.341); // #d34857
        vec3 c2 = vec3(0.996, 0.686, 0.482); // #ffaf7b
        mappedColor = getGradientColor(luma, c0, c1, c2);
    } else if (uPreset == 1) {
        // Ocean: Deep Blue -> Teal -> Mint/Light Green
        vec3 c0 = vec3(0.043, 0.106, 0.235); // #0b1a3c
        vec3 c1 = vec3(0.008, 0.667, 0.690); // #02aab0
        vec3 c2 = vec3(0.627, 0.961, 0.745); // #a0f5be
        mappedColor = getGradientColor(luma, c0, c1, c2);
    } else if (uPreset == 2) {
        // Forest: Deep Green -> Olive Green -> Lime/Pale Yellow-Green
        vec3 c0 = vec3(0.039, 0.157, 0.188); // #0a2830
        vec3 c1 = vec3(0.337, 0.671, 0.184); // #56ab2f
        vec3 c2 = vec3(0.659, 1.000, 0.471); // #a8ff78
        mappedColor = getGradientColor(luma, c0, c1, c2);
    } else if (uPreset == 3) {
        // Retro: Dark Brown/Black -> Copper/Rust Orange -> Gold
        vec3 c0 = vec3(0.039, 0.020, 0.020); // #0a0505
        vec3 c1 = vec3(0.863, 0.196, 0.078); // #f12711 or #dc3214
        vec3 c2 = vec3(0.961, 0.745, 0.118); // #f5af19 or #f1ba1e
        mappedColor = getGradientColor(luma, c0, c1, c2);
    } else {
        // Manga: Black -> Grey -> White
        vec3 c0 = vec3(0.059, 0.059, 0.078); // #0f0f14
        vec3 c1 = vec3(0.510, 0.510, 0.529); // #828287
        vec3 c2 = vec3(0.980, 0.980, 0.980); // #fafafa
        mappedColor = getGradientColor(luma, c0, c1, c2);
    }
    
    // Output color with original alpha (and re-multiply alpha)
    fragColor = vec4(mappedColor * srcColor.a, srcColor.a);
}
