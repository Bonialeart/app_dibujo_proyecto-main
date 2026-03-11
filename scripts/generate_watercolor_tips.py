"""
generate_watercolor_tips.py
Genera texturas de puntas de pincel de acuarela PROFESIONALES y DISTINTAS.
Cada pincel tiene una forma única basada en comportamiento real de acuarela.
"""

import numpy as np
from PIL import Image, ImageFilter, ImageDraw
import os, math, random

SIZE = 512
HALF = SIZE // 2
OUT_DIR = r"E:\Rescate_Proyecto\assets\brushes"
os.makedirs(OUT_DIR, exist_ok=True)

rng = np.random.default_rng(42)

# ─── Utilidades ──────────────────────────────────────────────────────────────

def save(arr, name):
    # arr es float [0..1], guardamos como PNG L (grayscale)
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), mode='L')
    path = os.path.join(OUT_DIR, name)
    img.save(path)
    print(f"  Guardado: {name}  ({arr.max():.3f} max)")

def grid():
    y, x = np.mgrid[-HALF:HALF, -HALF:HALF].astype(np.float32)
    return x / HALF, y / HALF          # rango -1..1 en ambos ejes

def smooth_noise(scale, octaves=4, seed=0):
    """Perlin-like fractal noise (puro numpy)."""
    r = np.random.default_rng(seed)
    h = np.zeros((SIZE, SIZE), np.float32)
    amp = 1.0
    for o in range(octaves):
        freq = max(int(scale * (2 ** o)), 1)
        small = r.random((freq, freq)).astype(np.float32)
        big = np.array(Image.fromarray((small * 255).astype(np.uint8)).resize(
            (SIZE, SIZE), Image.BICUBIC)) / 255.0
        h += big * amp
        amp *= 0.5
    h -= h.min()
    mx = h.max()
    if mx > 0:
        h /= mx
    return h

def radial_dist():
    x, y = grid()
    return np.sqrt(x**2 + y**2)

def gaussian_blur_arr(arr, radius):
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8))
    blurred = img.filter(ImageFilter.GaussianBlur(radius=radius))
    return np.array(blurred).astype(np.float32) / 255.0

# ─── 1. WATERCOLOR ROUND (clásico, orgánico) ─────────────────────────────────
def make_wc_round():
    """Punta ovalada con borde irregular de acuarela — distinto a las generadas antes."""
    x, y = grid()
    # Oval ligeramente elongada (ratio ~1.3)
    r = np.sqrt((x * 0.77) ** 2 + (y * 1.0) ** 2)

    # Forma base suave
    base = np.clip(1.0 - r, 0, 1)
    base = np.power(base, 0.65)

    # Ruido de borde orgánico (3 octavas)
    noise_edge = smooth_noise(6, octaves=3, seed=10)
    # Desplaza el borde con el ruido
    edge_disp = 0.18 * noise_edge - 0.09
    r_warped = np.sqrt((x * 0.77 + edge_disp * 0.4) ** 2 + (y + edge_disp * 0.6) ** 2)
    warp_mask = np.clip(1.0 - r_warped, 0, 1)
    warp_mask = np.power(warp_mask, 0.7)

    result = np.maximum(base * 0.4, warp_mask * 0.9)

    # Anillo de tide-mark: pigmento acumulado en el borde
    ring_in  = np.clip(1.0 - smoothstep(0.72, 0.82, r), 0, 1)
    ring_out = np.clip(smoothstep(0.65, 0.75, r), 0, 1)
    tide_mark = ring_in * ring_out * 0.55
    result = np.clip(result + tide_mark, 0, 1)

    # Textura interna de granulación
    grain = smooth_noise(14, octaves=4, seed=20)
    interior_mask = np.clip(1.0 - r / 0.6, 0, 1)
    result = result * (1.0 - interior_mask * grain * 0.22)

    # Centro ligeramente hueco (el agua dilata el pigmento hacia afuera)
    center_hollow = np.exp(-r**2 / 0.08) * 0.35
    result = np.clip(result - center_hollow, 0, 1)

    result = gaussian_blur_arr(result, 3)
    save(result, "wc_round.png")

# ─── 2. WATERCOLOR WET BLOOMING ──────────────────────────────────────────────
def make_wc_wet_bloom():
    """Muy húmedo — borde irregular con cauliflower/backrun visible."""
    x, y = grid()
    r = np.sqrt(x**2 + y**2)

    # Forma madre: blob irregular asimétrico
    noise1 = smooth_noise(5, octaves=4, seed=31)
    noise2 = smooth_noise(9, octaves=3, seed=32)
    # Deformar las coordenadas
    dx = (noise1 - 0.5) * 0.45
    dy = (noise2 - 0.5) * 0.45
    xd, yd = x + dx, y + dy
    rd = np.sqrt(xd**2 + yd**2)

    base = np.clip(1.0 - rd * 1.1, 0, 1)
    base = np.power(base, 0.45)  # borde muy suave

    # Anillos de backrun: varios anillos concéntricos irregulares
    for rad, strength in [(0.55, 0.55), (0.72, 0.40), (0.88, 0.28)]:
        ring = np.exp(-((rd - rad) ** 2) / 0.004) * strength
        ring *= (smooth_noise(8, octaves=2, seed=40 + int(rad * 100)) * 0.8 + 0.2)
        base = np.clip(base + ring, 0, 1)

    # Nodos de cauliflower en el borde extremo
    cauliflower = smooth_noise(18, octaves=2, seed=55)
    outer_mask = smoothstep(0.75, 0.95, rd)
    base = np.clip(base + outer_mask * cauliflower * 0.35, 0, 1)

    # Centro muy hueco (agua limpia empuja pigmento hacia fuera)
    center_clear = np.exp(-r**2 / 0.05) * 0.7
    base = np.clip(base - center_clear, 0, 1)

    base = gaussian_blur_arr(base, 2)
    save(base, "wc_wet_bloom.png")

# ─── 3. WATERCOLOR DRY BRUSH ─────────────────────────────────────────────────
def make_wc_dry_brush():
    """Pincel seco — múltiples carriles de cerdas con espacios, vectorizado."""
    canvas = np.zeros((SIZE, SIZE), np.float32)
    y_arr, x_arr = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)

    noise_texture = smooth_noise(14, octaves=3, seed=70)

    n_bristles = 7
    total_spread = 170
    length = 360
    brush_h = 10   # semi-altura de cada cerda en pixels

    x0 = (SIZE - length) // 2
    x1 = x0 + length

    for i in range(n_bristles):
        frac = i / (n_bristles - 1)
        cy_b = HALF + (frac - 0.5) * total_spread

        # Distancia transversal a esta cerda
        dist_y = np.abs(y_arr - cy_b)
        # Dentro del rango de longitud
        in_x = (x_arr >= x0) & (x_arr <= x1)
        taper = np.clip(np.minimum(x_arr - x0, x1 - x_arr) / 50.0, 0, 1)
        trans  = np.clip(1.0 - dist_y / brush_h, 0, 1) ** 1.4

        val = taper * trans * in_x.astype(np.float32)
        # Textura de pincel seco
        val *= (0.45 + noise_texture * 0.65)
        canvas = np.maximum(canvas, val)

    result = gaussian_blur_arr(canvas, 2)
    save(result, "wc_dry_brush.png")



# ─── 4. WATERCOLOR FLAT WASH ─────────────────────────────────────────────────
def make_wc_flat_wash():
    """Brocha plana ancha — bordes irregulares arriba y abajo, uniforme en el centro. Vectorizado."""
    y_idx, x_idx = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)

    brush_w = 420
    brush_h = 120
    x0 = (SIZE - brush_w) // 2
    x1 = x0 + brush_w
    y0 = (SIZE - brush_h) // 2
    y1 = y0 + brush_h

    noise_top = smooth_noise(7, octaves=3, seed=80)
    noise_bot = smooth_noise(7, octaves=3, seed=81)
    noise_tex  = smooth_noise(16, octaves=3, seed=82)

    # Deformación vertical por columna (1D → broadcast)
    top_off_col = ((noise_top[HALF, :] - 0.5) * 28).astype(np.float32)  # (SIZE,)
    bot_off_col = ((noise_bot[HALF, :] - 0.5) * 28).astype(np.float32)

    # Boundaries por columna → broadcast a (SIZE, SIZE)
    actual_y0 = y0 + top_off_col[np.newaxis, :]  # (1, SIZE) → broadcast
    actual_y1 = y1 + bot_off_col[np.newaxis, :]

    in_x = (x_idx >= x0) & (x_idx <= x1)
    in_y = (y_idx >= actual_y0) & (y_idx <= actual_y1)
    inside = in_x & in_y

    # Distancia a borde vertical
    dist_top = y_idx - actual_y0
    dist_bot = actual_y1 - y_idx
    edge_dist = np.minimum(dist_top, dist_bot) / 18.0

    # Taper horizontal
    hprog = np.clip((x_idx - x0) / (x1 - x0), 0, 1)
    taper = np.clip(np.minimum(hprog, 1.0 - hprog) * 10.0, 0, 1)

    val = np.clip(edge_dist, 0, 1) * taper * (0.55 + noise_tex * 0.45)

    # Tide-mark en bordes
    tide = (dist_top < 12) | (dist_bot < 12)
    val = np.where(tide & inside, np.minimum(val + 0.42, 1.0), val)

    val = np.where(inside, val, 0.0).astype(np.float32)
    result = gaussian_blur_arr(val, 2.5)
    save(result, "wc_flat_wash.png")



# ─── 5. WET-ON-WET (blob muy orgánico) ───────────────────────────────────────
def make_wc_wet_on_wet():
    """Forma completamente orgánica — como una gota de acuarela sobre papel húmedo."""
    x, y = grid()

    # Múltiples blobs con posiciones aleatorias fijas para consistencia
    blobs = [
        (0.0,  0.0,  0.55, 1.0),
        (0.18, 0.12, 0.38, 0.7),
        (-0.22, 0.15, 0.32, 0.6),
        (0.10, -0.20, 0.28, 0.5),
        (-0.12, -0.18, 0.25, 0.45),
        (0.30,  0.05, 0.20, 0.4),
        (-0.28,  0.08, 0.18, 0.35),
    ]

    canvas = np.zeros((SIZE, SIZE), np.float32)
    noises = [smooth_noise(6 + i, octaves=3, seed=90 + i) for i in range(len(blobs))]

    for idx, (bx, by, brad, bstr) in enumerate(blobs):
        dist = np.sqrt((x - bx)**2 + (y - by)**2)
        # Deformar con ruido
        nd = noises[idx]
        dist_w = dist + (nd - 0.5) * brad * 0.4
        blob = np.clip(1.0 - dist_w / brad, 0, 1)
        blob = np.power(blob, 0.55) * bstr
        canvas = np.maximum(canvas, blob)

    # Suavizar la unión de blobs
    canvas = gaussian_blur_arr(canvas, 5)

    # Anillo de pigmento concentrado en todo el borde exterior del blob
    # (efecto tide-mark de acuarela mojada sobre mojada)
    ex = gaussian_blur_arr(canvas, 18)
    edge_ring = np.clip(ex - gaussian_blur_arr(canvas, 30), 0, 1)
    canvas = np.clip(canvas + edge_ring * 0.5, 0, 1)

    # Textura interna de granulación irregular
    grain = smooth_noise(20, octaves=4, seed=99)
    canvas = canvas * (1.0 - canvas * grain * 0.18)

    save(canvas, "wc_wet_on_wet.png")

# ─── 6. CALLIGRAPHY WATERCOLOR ────────────────────────────────────────────────
def make_wc_calligraphy():
    """Punta de cálamo acuarelado — muy ancha en perpendicular, estrecha en el eje."""
    x, y = grid()

    # Forma: elipse muy aplanada (ratio 5:1)
    r = np.sqrt((x * 0.22) ** 2 + (y * 1.1) ** 2)

    base = np.clip(1.0 - r, 0, 1)
    base = np.power(base, 0.6)

    # Bordes irregulares (pincel de pelo natural)
    noise = smooth_noise(10, octaves=4, seed=110)
    edge_noise = (noise - 0.5) * 0.12
    r2 = np.sqrt((x * 0.22 + edge_noise) ** 2 + (y * 1.1 + edge_noise * 0.5) ** 2)
    base2 = np.clip(1.0 - r2, 0, 1)
    base2 = np.power(base2, 0.5)

    result = np.maximum(base * 0.3, base2)

    # Cerdas: líneas sutiles en el eje Y (dirección del trazo)
    bristle_noise = smooth_noise(40, octaves=1, seed=120)
    result *= (0.7 + bristle_noise * 0.35)

    result = gaussian_blur_arr(result, 2)
    save(result, "wc_calligraphy.png")

# ─── 7. SPLATTER / INK DROP ───────────────────────────────────────────────────
def make_wc_splatter():
    """Salpicado de tinta — múltiples gotas irregulares, núcleo central."""
    canvas = np.zeros((SIZE, SIZE), np.float32)

    # Núcleo central
    x, y = grid()
    r_center = np.sqrt((x * 0.8)**2 + (y * 1.0)**2)
    core = np.clip(1.0 - r_center * 2.2, 0, 1)
    core = np.power(core, 0.5)

    # Deformar núcleo
    dn = smooth_noise(8, octaves=3, seed=130)
    r_d = np.sqrt((x * 0.8 + (dn-0.5)*0.2)**2 + (y + (dn-0.5)*0.25)**2)
    core2 = np.clip(1.0 - r_d * 2.0, 0, 1)
    core = np.maximum(core * 0.7, core2)

    canvas = gaussian_blur_arr(core, 3)

    # Gotas satélite
    r_seed = np.random.RandomState(200)
    for _ in range(14):
        angle = r_seed.uniform(0, 2 * math.pi)
        dist_c = r_seed.uniform(0.3, 0.75)
        drop_x = int(HALF + math.cos(angle) * dist_c * HALF)
        drop_y = int(HALF + math.sin(angle) * dist_c * HALF)
        drop_r = r_seed.randint(6, 28)
        drop_str = r_seed.uniform(0.4, 0.95)

        img_tmp = Image.fromarray((canvas * 255).astype(np.uint8))
        draw = ImageDraw.Draw(img_tmp)
        # Elipse ligeramente deformada
        ex = r_seed.randint(-5, 5)
        ey = r_seed.randint(-5, 5)
        draw.ellipse([drop_x - drop_r + ex, drop_y - drop_r + ey,
                      drop_x + drop_r, drop_y + drop_r],
                     fill=int(200 * drop_str))
        canvas = np.array(img_tmp).astype(np.float32) / 255.0

    canvas = gaussian_blur_arr(canvas, 1.5)
    save(canvas, "wc_splatter.png")

# ─── Función auxiliar ────────────────────────────────────────────────────────
def smoothstep(edge0, edge1, arr):
    t = np.clip((arr - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

# ─── MAIN ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=== Generando puntas de pincel de acuarela profesionales ===")
    print(f"Tamaño: {SIZE}x{SIZE}px → {OUT_DIR}\n")

    make_wc_round()
    make_wc_wet_bloom()
    make_wc_dry_brush()
    make_wc_flat_wash()
    make_wc_wet_on_wet()
    make_wc_calligraphy()
    make_wc_splatter()

    print("\n✅ Todas las texturas generadas.")
