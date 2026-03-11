#version 330 core

in vec2 vTexCoord; // 0..1 over the screen (Backdrop UV)
out vec4 fragColor;

uniform sampler2D uBackdrop; // The background (Screen copy)
uniform sampler2D uSource;   // The layer (Full Canvas buffer)
uniform float uOpacity;      // Layer opacity
uniform int uMode;           // Blend Mode Index

uniform vec2 uScreenSize;    // Width, Height of viewport
uniform vec2 uLayerSize;     // Width, Height of layer (Canvas size)
uniform vec2 uViewOffset;    // Pan offset
uniform float uZoom;         // Zoom level

uniform sampler2D uMask;     // Clipping Mask Texture
uniform int uHasMask;        // 1 if masked, 0 otherwise
uniform float uIsPreview;    // 1.0 if drawing, 0.0 otherwise

// Setup Constants derived from C++ BlendMode enum
const int MODE_NORMAL = 0;
const int MODE_MULTIPLY = 1;
const int MODE_SCREEN = 2;
const int MODE_OVERLAY = 3;
const int MODE_SOFTLIGHT = 4;
const int MODE_HARDLIGHT = 5;
const int MODE_COLORDODGE = 6;
const int MODE_COLORBURN = 7;
const int MODE_DARKEN = 8;
const int MODE_LIGHTEN = 9;
const int MODE_DIFFERENCE = 10;
const int MODE_EXCLUSION = 11;
const int MODE_HUE = 12;
const int MODE_SATURATION = 13;
const int MODE_COLOR = 14;
const int MODE_LUMINOSITY = 15;

float getLum(vec3 c) { return 0.3 * c.r + 0.59 * c.g + 0.11 * c.b; }
float getSat(vec3 c) { return max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b); }

vec3 setLum(vec3 c, float l) {
    float d = l - getLum(c);
    c += d;
    float l_new = getLum(c);
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    if (n < 0.0) {
        c = l_new + (c - l_new) * l_new / (l_new - n);
    }
    if (x > 1.0) {
        c = l_new + (c - l_new) * (1.0 - l_new) / (x - l_new);
    }
    return c;
}

vec3 setSat(vec3 c, float s) {
    float cmin = min(min(c.r, c.g), c.b);
    float cmax = max(max(c.r, c.g), c.b);
    // Simplified branchy setSat
    if (cmax > cmin) {
        if (c.r == cmax && c.b == cmin) { c.g = (((c.g - c.b) * s) / (c.r - c.b)); c.r = s; c.b = 0.0; } 
        else if (c.r == cmax && c.g == cmin) { c.b = (((c.b - c.g) * s) / (c.r - c.g)); c.r = s; c.g = 0.0; } 
        else if (c.g == cmax && c.b == cmin) { c.r = (((c.r - c.b) * s) / (c.g - c.b)); c.g = s; c.b = 0.0; } 
        else if (c.g == cmax && c.r == cmin) { c.b = (((c.b - c.r) * s) / (c.g - c.r)); c.g = s; c.r = 0.0; } 
        else if (c.b == cmax && c.g == cmin) { c.r = (((c.r - c.g) * s) / (c.b - c.g)); c.b = s; c.g = 0.0; } 
        else { c.g = (((c.g - c.r) * s) / (c.b - c.r)); c.b = s; c.r = 0.0; }
        return c;
    } else {
        return vec3(0.0);
    }
}

void main() {
    // 1. Calculate Layer UV based on Viewport transforms
    // Convert Bottom-Left UV to Top-Left UV for GUI Coordinate matching
    vec2 screenUV_TL = vec2(vTexCoord.x, 1.0 - vTexCoord.y);
    vec2 screenPixel = screenUV_TL * uScreenSize;
    
    // Reverse transform: (screen - offset*zoom) / zoom = canvas_pixel
    vec2 canvasPixel = (screenPixel - (uViewOffset * uZoom)) / uZoom;
    
    // Clip Logic (if outside canvas)
    if (canvasPixel.x < 0.0 || canvasPixel.y < 0.0 || 
        canvasPixel.x > uLayerSize.x || canvasPixel.y > uLayerSize.y) {
        // Outside layer bounds: Just return backdrop
        fragColor = texture(uBackdrop, vTexCoord);
        return;
    }
    
    vec2 layerUV = canvasPixel / uLayerSize;
    
    // Sample Textures
    vec4 S = texture(uSource, layerUV);
    vec4 D = texture(uBackdrop, vTexCoord);

    // If source is empty, return dest
    if (S.a <= 0.0) {
        fragColor = D;
        return;
    }

    float sa = S.a * uOpacity;
    float da = D.a;
    
    // Clipping Mask Logic
    if (uHasMask == 1) {
        float maskAlpha = texture(uMask, layerUV).a;
        // BLOQUEO ESTRICTO: Descarte inmediato si no hay base.
        if (maskAlpha < 0.001) {
            fragColor = texture(uBackdrop, vTexCoord);
            return;
        }
        sa *= maskAlpha;
        S.rgb *= maskAlpha;
    }

    // Un-premultiply colors for blending math
    vec3 Cs = (sa > 0.005) ? S.rgb / sa : vec3(0.0);
    vec3 Cb = (da > 0.005) ? D.rgb / da : vec3(0.0);
    
    vec3 B = vec3(0.0);

    // --- BLEND MODES (Standard W3C Formulas) ---
    if (uMode == MODE_NORMAL) { B = Cs; } 
    else if (uMode == MODE_MULTIPLY) { B = Cs * Cb; }
    else if (uMode == MODE_SCREEN) { B = 1.0 - (1.0 - Cs) * (1.0 - Cb); }
    else if (uMode == MODE_OVERLAY) { B = mix(2.0 * Cs * Cb, 1.0 - 2.0 * (1.0 - Cs) * (1.0 - Cb), step(0.5, Cb)); }
    else if (uMode == MODE_DARKEN) { B = min(Cs, Cb); }
    else if (uMode == MODE_LIGHTEN) { B = max(Cs, Cb); }
    else if (uMode == MODE_COLORDODGE) { B = (Cs == vec3(1.0)) ? vec3(1.0) : min(vec3(1.0), Cb / (1.0 - Cs)); }
    else if (uMode == MODE_COLORBURN) { B = (Cs == vec3(0.0)) ? vec3(0.0) : 1.0 - min(vec3(1.0), (1.0 - Cb) / Cs); }
    else if (uMode == MODE_HARDLIGHT) { B = mix(2.0 * Cs * Cb, 1.0 - 2.0 * (1.0 - Cs) * (1.0 - Cb), step(0.5, Cs)); }
    else if (uMode == MODE_SOFTLIGHT) {
        B = mix(Cb - (1.0 - 2.0 * Cs) * Cb * (1.0 - Cb),
                Cb + (2.0 * Cs - 1.0) * (sqrt(Cb) - Cb),
                step(0.5, Cs));
    }
    else if (uMode == MODE_DIFFERENCE) { B = abs(Cs - Cb); }
    else if (uMode == MODE_EXCLUSION) { B = Cs + Cb - 2.0 * Cs * Cb; }
    else if (uMode == MODE_HUE) { B = setLum(setSat(Cs, getSat(Cb)), getLum(Cb)); }
    else if (uMode == MODE_SATURATION) { B = setLum(setSat(Cb, getSat(Cs)), getLum(Cb)); }
    else if (uMode == MODE_COLOR) { B = setLum(Cs, getLum(Cb)); }
    else if (uMode == MODE_LUMINOSITY) { B = setLum(Cb, getLum(Cs)); }
    else { B = Cs; }

    // --- FINAL COMPOSITING ---
    // Composite the blended result (sa * da * B) plus the non-overlapping source and backdrop parts
    float a_out = sa + da - sa * da;
    vec3 color_out = S.rgb * (1.0 - da) + D.rgb * (1.0 - sa) + (sa * da) * B;
    
    fragColor = vec4(color_out, a_out);
}
