#version 330 core
// brush.frag - Premium Brush Engine Shader
// Multiple brush types: Pencil, Ink, Watercolor, Oil, Acrylic, Airbrush
// Implements per-type visual behaviors

in vec2 vUV;
in vec2 vCanvasCoords; 

uniform sampler2D uBrushTip;   
uniform sampler2D uPaperTex;   
uniform sampler2D uCanvasTex;  // Previous Canvas state (Ping-Pong)
uniform sampler2D uWetMap;     

uniform vec4 uColor;          
uniform float uPressure;      
uniform float uHardness;
uniform int uMode;             // Legacy mode
uniform int uBrushType;        // 0=Round, 1=Pencil, 2=Airbrush, 3=Ink, 4=Watercolor, 5=Oil, 6=Acrylic, 7=Eraser
uniform float uWetness;        // For color mixing (Oil/Watercolor)

out vec4 fragColor;

// === BRUSH TYPE CONSTANTS ===
#define TYPE_ROUND 0
#define TYPE_PENCIL 1
#define TYPE_AIRBRUSH 2
#define TYPE_INK 3
#define TYPE_WATERCOLOR 4
#define TYPE_OIL 5
#define TYPE_ACRYLIC 6
#define TYPE_ERASER 7

// === NOISE FUNCTIONS ===
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);  // Smoothstep
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal Brownian Motion for detailed grain
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// === KUBELKA-MUNK COLOR MIXING ===
vec3 rgbToK(vec3 rgb) {
    return (vec3(1.0) - rgb) * (vec3(1.0) - rgb) / (2.0 * rgb + 0.001);
}

vec3 kToRGB(vec3 k) {
    return vec3(1.0) + k - sqrt(max(k * k + 2.0 * k, 0.0));
}

void main() {
    // Calculate normalized distance from center (0 = center, 1 = edge)
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(vUV, center) * 2.0;
    
    // Discard pixels outside the brush circle
    if (dist > 1.05) discard;
    
    // Anti-aliasing at edge using fwidth
    float delta = fwidth(dist);
    float antiAlias = 1.0 - smoothstep(1.0 - delta * 2.0, 1.0, dist);
    
    // Sample textures
    vec4 canvasState = texture(uCanvasTex, vCanvasCoords);
    float brushTipValue = texture(uBrushTip, vUV).a;
    float paperGrain = texture(uPaperTex, vCanvasCoords * 3.0).r;
    
    float alpha = 0.0;
    vec3 finalColor = uColor.rgb;
    
    // === BRUSH TYPE SPECIFIC BEHAVIOR ===
    
    if (uBrushType == TYPE_PENCIL) {
        // --------------------------------------------------------
        // PENCIL: Grainy texture simulating graphite on paper
        // --------------------------------------------------------
        // Multi-frequency noise for paper texture
        float grainFine = noise(vCanvasCoords * 400.0);
        float grainCoarse = noise(vCanvasCoords * 100.0);
        float grain = grainFine * 0.6 + grainCoarse * 0.4;
        
        // Base falloff
        float falloff = 1.0 - smoothstep(0.5, 1.0, dist);
        falloff = pow(falloff, 0.8);
        
        // Grain threshold based on pressure (more pressure = more coverage)
        float threshold = 1.0 - uPressure * 0.8;
        float grainMask = smoothstep(threshold - 0.2, threshold + 0.1, grain);
        
        // Paper tooth interaction
        float paperInteraction = mix(1.0, paperGrain, 0.4);
        
        alpha = falloff * grainMask * paperInteraction * uPressure;
    }
    else if (uBrushType == TYPE_AIRBRUSH) {
        // --------------------------------------------------------
        // AIRBRUSH: Ultra-soft gaussian spray
        // --------------------------------------------------------
        // Gaussian falloff: exp(-x^2 * k)
        float gaussian = exp(-dist * dist * 4.0);
        
        // Add subtle spray noise
        float spray = noise(vCanvasCoords * 150.0 + uPressure) * 0.15;
        
        alpha = gaussian * (1.0 + spray) * uColor.a;
    }
    else if (uBrushType == TYPE_INK) {
        // --------------------------------------------------------
        // INK: Super sharp edges for clean G-pen style lines
        // --------------------------------------------------------
        // Very hard edge with perfect anti-aliasing
        float edgeSharpness = 0.95;
        
        if (dist < edgeSharpness) {
            alpha = 1.0;
        } else {
            // 1-pixel anti-aliased edge
            alpha = 1.0 - smoothstep(edgeSharpness, 1.0, dist);
        }
        
        // Apply pressure to alpha (ink is fully opaque unless lifting)
        alpha *= smoothstep(0.0, 0.3, uPressure);
    }
    else if (uBrushType == TYPE_WATERCOLOR) {
        // --------------------------------------------------------
        // WATERCOLOR: Wet edge (coffee ring) + transparent + mixing
        // --------------------------------------------------------
        // Turbulence distortion
        float turb = noise(vCanvasCoords * 80.0 + uPressure * 0.5);
        vec2 distortedUV = vUV + (turb - 0.5) * 0.05 * (1.1 - uPressure);
        float distDistorted = distance(distortedUV, center) * 2.0;
        
        // Core: soft radial gradient
        float core = pow(1.0 - smoothstep(0.0, 0.9, distDistorted), 1.2);
        
        // Coffee ring effect: pigment accumulates at edge
        float edgeRing = smoothstep(0.75, 0.95, distDistorted) * 0.5;
        edgeRing *= (1.0 - smoothstep(0.95, 1.0, distDistorted));
        
        // Paper granulation (pigment settles in valleys)
        float granulation = smoothstep(1.0 - uPressure * 0.5, 1.0, paperGrain) * 0.3;
        
        alpha = (core + edgeRing) * 0.6 + granulation;
        
        // Kubelka-Munk subtractive mixing with canvas
        if (canvasState.a > 0.01) {
            vec3 K_canvas = rgbToK(canvasState.rgb);
            vec3 K_pigment = rgbToK(uColor.rgb);
            vec3 K_final = mix(K_canvas, K_canvas + K_pigment, alpha * 0.7);
            finalColor = kToRGB(K_final);
        }
        
        alpha *= uColor.a * 0.8;  // Watercolor is always translucent
    }
    else if (uBrushType == TYPE_OIL) {
        // --------------------------------------------------------
        // OIL: Bristle texture + thick paint + color mixing
        // --------------------------------------------------------
        // Bristle texture (stretched noise to simulate brush hairs)
        float bristle = noise(vCanvasCoords * vec2(80.0, 30.0));
        
        // Paint thickness (spherical buildup)
        float thickness = sqrt(max(0.0, 1.0 - dist * dist));
        
        // Combine with bristle texture
        alpha = thickness * (0.7 + 0.3 * bristle);
        
        // Pressure affects paint load
        alpha *= (0.4 + 0.6 * uPressure);
        
        // Color mixing with existing paint
        if (uWetness > 0.01 && canvasState.a > 0.1) {
            float mixAmount = uWetness * canvasState.a * 0.5;
            finalColor = mix(uColor.rgb, canvasState.rgb, mixAmount);
        }
        
        alpha *= uColor.a;
    }
    else if (uBrushType == TYPE_ACRYLIC) {
        // --------------------------------------------------------
        // ACRYLIC: Flat with impasto (rough irregular edges)
        // --------------------------------------------------------
        // Add noise to edge for irregular boundary
        float edgeNoise = noise(vCanvasCoords * 150.0) * 0.2;
        float irregularEdge = uHardness + edgeNoise;
        
        // Sharp but irregular edge
        alpha = 1.0 - smoothstep(irregularEdge - 0.1, irregularEdge + 0.1, dist);
        
        // Slight texture inside (canvas texture showing through)
        float innerTexture = noise(vCanvasCoords * 50.0) * 0.08 + 0.92;
        alpha *= innerTexture;
        
        alpha *= uColor.a * uPressure;
    }
    else if (uBrushType == TYPE_ERASER) {
        // --------------------------------------------------------
        // ERASER: Removes paint (works on alpha)
        // --------------------------------------------------------
        float eraseFalloff = 1.0 - smoothstep(uHardness, 1.0, dist);
        float eraseStrength = eraseFalloff * uColor.a * uPressure;
        
        // Output: reduce canvas alpha
        float newAlpha = max(0.0, canvasState.a - eraseStrength);
        fragColor = vec4(canvasState.rgb, newAlpha);
        return;
    }
    else {
        // --------------------------------------------------------
        // ROUND (Default): Variable hardness brush
        // --------------------------------------------------------
        if (uHardness >= 0.99) {
            // Completely hard
            alpha = step(dist, 1.0);
        } else if (uHardness <= 0.01) {
            // Completely soft (linear falloff + smoothstep)
            alpha = 1.0 - dist;
            alpha = alpha * alpha * (3.0 - 2.0 * alpha);
        } else {
            // Variable hardness
            if (dist < uHardness) {
                alpha = 1.0;
            } else {
                float t = (dist - uHardness) / (1.0 - uHardness);
                alpha = 1.0 - t * t * (3.0 - 2.0 * t);
            }
        }
        
        alpha *= uColor.a * uPressure;
    }
    
    // Apply edge anti-aliasing
    alpha *= antiAlias;
    
    // Clamp alpha
    alpha = clamp(alpha, 0.0, 1.0);
    
    // Skip nearly transparent pixels
    if (alpha < 0.002) discard;
    
    // === FINAL OUTPUT ===
    // Premium dithering to eliminate banding
    float dither = (hash(gl_FragCoord.xy + uPressure) - 0.5) / 255.0;
    finalColor = clamp(finalColor + dither, 0.0, 1.0);
    
    // Premultiplied alpha output (for correct blending)
    fragColor = vec4(finalColor * alpha, alpha);
}
