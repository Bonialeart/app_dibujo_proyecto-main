"""
ArtFlow Studio — Regenerador de Texturas de Pinceles Pequeñas
=============================================================
Este script detecta las texturas PNG en assets/textures/ que son molto
pequeñas (< 8 KB) y las reemplaza con versiones de 512x512 pixel generadas
proceduralmente, manteniendo el mismo nombre de archivo.

Las texturas generadas son ruido de alta frecuencia en escala de grises,
apropiadas para usar como máscaras de forma de pincel (brush tips).

Uso:
    python scripts/regenerate_small_textures.py
"""

import os
import struct
import zlib
import math
import random

TEXTURES_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'textures')
SIZE_THRESHOLD_BYTES = 8192  # Texturas menores a 8 KB se consideran "pequeñas"
OUTPUT_SIZE = 512             # Nueva resolución: 512x512

# ─────────────────────────────────────────────────────────────
# Generadores procedurales utilizando solo stdlib (sin PIL/numpy)
# ─────────────────────────────────────────────────────────────

def _write_png_grayscale(filepath, pixels, w, h):
    """Escribe un PNG en escala de grises (8-bit) a partir de una lista de ints 0-255."""
    def png_chunk(name, data):
        chunk_len = len(data)
        crc = zlib.crc32(name + data) & 0xffffffff
        return struct.pack('>I', chunk_len) + name + data + struct.pack('>I', crc)

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', w, h, 8, 0, 0, 0, 0)  # 8-bit greyscale
    ihdr = png_chunk(b'IHDR', ihdr_data)

    # Build raw image data (filter byte 0x00 = None per row)
    raw_rows = b''
    for y in range(h):
        row = b'\x00' + bytes(pixels[y * w:(y + 1) * w])
        raw_rows += row

    compressed = zlib.compress(raw_rows, 9)
    idat = png_chunk(b'IDAT', compressed)
    iend = png_chunk(b'IEND', b'')

    with open(filepath, 'wb') as f:
        f.write(sig + ihdr + idat + iend)

    print(f"  -> Escrito: {os.path.basename(filepath)} ({w}x{h} px)")


def _lerp(a, b, t):
    return a + (b - a) * t


def _smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def _fade(t):
    return t * t * t * (t * (t * 6 - 15) + 10)


def _grad(h, x, y):
    h = h & 3
    if h == 0: return  x + y
    if h == 1: return -x + y
    if h == 2: return  x - y
    return -x - y


class PerlinNoise:
    """Perlin Noise 2D simplificado en Python puro."""
    def __init__(self, seed=0):
        rng = random.Random(seed)
        p = list(range(256))
        rng.shuffle(p)
        self.p = p * 2

    def noise(self, x, y):
        xi = int(math.floor(x)) & 255
        yi = int(math.floor(y)) & 255
        xf = x - math.floor(x)
        yf = y - math.floor(y)
        u = _fade(xf)
        v = _fade(yf)
        p = self.p
        aa = p[p[xi]     + yi]
        ab = p[p[xi]     + yi + 1]
        ba = p[p[xi + 1] + yi]
        bb = p[p[xi + 1] + yi + 1]
        x1 = _lerp(_grad(aa, xf,     yf    ), _grad(ba, xf - 1, yf    ), u)
        x2 = _lerp(_grad(ab, xf,     yf - 1), _grad(bb, xf - 1, yf - 1), u)
        return (_lerp(x1, x2, v) + 1) / 2  # Normaliza a [0, 1]

    def octaves(self, x, y, octs=4, persistence=0.5):
        val = 0.0
        amp = 1.0
        freq = 1.0
        total_amp = 0.0
        for _ in range(octs):
            val += self.noise(x * freq, y * freq) * amp
            total_amp += amp
            amp *= persistence
            freq *= 2.0
        return val / total_amp


# ─────────────────────────────────────────────────────────────
# Generadores específicos por nombre de pincel
# ─────────────────────────────────────────────────────────────

def make_perlin_tip(w, h, seed=42, scale=4.0, octaves=4, contrast=1.6, invert=False):
    """Tip procedural con ruido Perlin — bueno para pinceles orgánicos."""
    pn = PerlinNoise(seed)
    pixels = []
    for y in range(h):
        for x in range(w):
            nx = x / w * scale
            ny = y / h * scale
            v = pn.octaves(nx, ny, octs=octaves)
            # Aplica contraste
            v = (v - 0.5) * contrast + 0.5
            v = max(0.0, min(1.0, v))
            # Aplica máscara circular para que sea un dab redondo
            cx = (x / w - 0.5) * 2
            cy = (y / h - 0.5) * 2
            dist = math.sqrt(cx * cx + cy * cy)
            fade_mask = _smoothstep(1.0 - dist)
            v = v * fade_mask
            if invert:
                v = 1.0 - v
            pixels.append(int(v * 255))
    return pixels


def make_pencil_tip(w, h, seed=10, grain_freq=40, hardness=0.85):
    """Simula la textura de un lápiz — líneas de grafito finas."""
    pn = PerlinNoise(seed)
    pixels = []
    for y in range(h):
        for x in range(w):
            cx = (x / w - 0.5) * 2
            cy = (y / h - 0.5) * 2
            dist = math.sqrt(cx * cx + cy * cy)
            if dist >= 1.0:
                pixels.append(0)
                continue

            # Falloff principal
            edge = max(1.0 - hardness, 0.001)
            if dist < hardness:
                base = 1.0
            else:
                t = (dist - hardness) / edge
                base = 0.5 * (1.0 + math.cos(t * math.pi))

            # Líneas de grafito: noise de alta frecuencia en eje X
            nx = x / w * grain_freq
            ny = y / h * (grain_freq * 0.2)
            grain = pn.octaves(nx, ny, octs=2, persistence=0.6)
            # Mezcla base con grano
            v = base * (0.65 + grain * 0.35)
            v = max(0.0, min(1.0, v))
            pixels.append(int(v * 255))
    return pixels


def make_charcoal_tip(w, h, seed=77):
    """Tip de carboncillo — fragmentado y orgánico."""
    pn = PerlinNoise(seed)
    pn2 = PerlinNoise(seed + 100)
    pixels = []
    for y in range(h):
        for x in range(w):
            cx = (x / w - 0.5) * 2
            cy = (y / h - 0.5) * 2
            dist = math.sqrt(cx * cx + cy * cy)
            if dist >= 1.0:
                pixels.append(0)
                continue
            mask = _smoothstep(1.0 - dist) ** 0.7

            # Ruido de alta frecuencia para fragmentación
            nx = x / w * 8.0
            ny = y / h * 8.0
            n1 = pn.octaves(nx, ny, octs=5, persistence=0.55)
            n2 = pn2.octaves(nx * 0.5, ny * 0.5, octs=3, persistence=0.5)

            # Umbral para crear fragmentos negros
            combined = n1 * 0.7 + n2 * 0.3
            # Umbral adaptativo: bordes más transparentes
            threshold = 0.35 + (1.0 - mask) * 0.2
            if combined < threshold:
                v = 0.0
            else:
                v = _smoothstep((combined - threshold) / (1.0 - threshold))
                v = v * mask

            pixels.append(int(v * 255))
    return pixels


def make_soft_airbrush(w, h):
    """Airbrush suave — degradado Gaussiano puro."""
    pixels = []
    sigma = 0.32
    for y in range(h):
        for x in range(w):
            cx = x / w - 0.5
            cy = y / h - 0.5
            d2 = cx * cx + cy * cy
            v = math.exp(-d2 / (2 * sigma * sigma))
            pixels.append(int(v * 255))
    return pixels


def make_ink_tip(w, h, seed=33, hardness=0.96, scatter=0.03):
    """Tip de tinta — borde duro, ligeramente dentado."""
    pn = PerlinNoise(seed)
    pixels = []
    for y in range(h):
        for x in range(w):
            cx = (x / w - 0.5) * 2
            cy = (y / h - 0.5) * 2
            dist = math.sqrt(cx * cx + cy * cy)

            # Perturbación del borde
            angle = math.atan2(cy, cx)
            edge_noise = pn.noise(math.cos(angle) * 3.0, math.sin(angle) * 3.0)
            eff_dist = dist + (edge_noise - 0.5) * scatter * 2.0

            if eff_dist >= 1.0:
                pixels.append(0)
                continue

            edge = max(1.0 - hardness, 0.002)
            if eff_dist < hardness:
                v = 1.0
            else:
                t = (eff_dist - hardness) / edge
                v = 0.5 * (1.0 + math.cos(t * math.pi))

            pixels.append(int(v * 255))
    return pixels


def make_splatter_tip(w, h, seed=55, num_drops=18):
    """Tip de salpicadura — círculos pequeños distribuidos."""
    rng = random.Random(seed)
    pn = PerlinNoise(seed)
    canvas = [0.0] * (w * h)

    # Drops distribuidos aleatoriamente dentro del círculo principal
    for _ in range(num_drops):
        r_drop = rng.uniform(0.0, 0.9)
        angle = rng.uniform(0, 2 * math.pi)
        dx = r_drop * math.cos(angle)
        dy = r_drop * math.sin(angle)
        drop_r = rng.uniform(0.04, 0.15) * (1.0 - r_drop * 0.5)

        cx_px = int((dx / 2 + 0.5) * w)
        cy_px = int((dy / 2 + 0.5) * h)
        drop_px = int(drop_r * w / 2)

        for py in range(max(0, cy_px - drop_px - 2), min(h, cy_px + drop_px + 2)):
            for px in range(max(0, cx_px - drop_px - 2), min(w, cx_px + drop_px + 2)):
                ex = (px - cx_px) / max(drop_px, 1)
                ey = (py - cy_px) / max(drop_px, 1)
                d = math.sqrt(ex * ex + ey * ey)
                if d < 1.0:
                    v = _smoothstep(1.0 - d)
                    canvas[py * w + px] = max(canvas[py * w + px], v)

    return [int(v * 255) for v in canvas]


# ─────────────────────────────────────────────────────────────
# Mapeo de filename → generador
# ─────────────────────────────────────────────────────────────

GENERATORS = {
    # Pinceles de tinta y pluma
    'bic_pen.png':            lambda w, h: make_ink_tip(w, h, seed=1,  hardness=0.97, scatter=0.008),
    'fountain_pen.png':       lambda w, h: make_ink_tip(w, h, seed=2,  hardness=0.96, scatter=0.012),
    'gel_pen.png':            lambda w, h: make_ink_tip(w, h, seed=3,  hardness=0.98, scatter=0.005),
    'studio_pen.png':         lambda w, h: make_ink_tip(w, h, seed=4,  hardness=0.97, scatter=0.01),
    'light_pen.png':          lambda w, h: make_ink_tip(w, h, seed=5,  hardness=0.92, scatter=0.02),
    'brush_pen.png':          lambda w, h: make_pencil_tip(w, h, seed=6, grain_freq=25, hardness=0.8),
    'monoline.png':           lambda w, h: make_ink_tip(w, h, seed=7,  hardness=0.99, scatter=0.002),
    'monoline_calligraphy.png': lambda w, h: make_ink_tip(w, h, seed=8, hardness=0.98, scatter=0.005),
    'script.png':             lambda w, h: make_ink_tip(w, h, seed=9,  hardness=0.94, scatter=0.015),
    'rain.png':               lambda w, h: make_ink_tip(w, h, seed=20, hardness=0.96, scatter=0.008),
    'skinny_cap.png':         lambda w, h: make_ink_tip(w, h, seed=21, hardness=0.95, scatter=0.01),
    'fat_cap.png':            lambda w, h: make_ink_tip(w, h, seed=22, hardness=0.88, scatter=0.025),

    # Airbrush
    'hard_airbrush.png':      lambda w, h: make_pencil_tip(w, h, seed=30, grain_freq=0, hardness=0.95),
    'medium_airbrush.png':    lambda w, h: make_soft_airbrush(w, h),
    'shape_airbrush_soft.png':lambda w, h: make_soft_airbrush(w, h),
    'shape_soft_circle.png':  lambda w, h: make_soft_airbrush(w, h),
    'shape_hard_circle.png':  lambda w, h: make_ink_tip(w, h, seed=31, hardness=0.97, scatter=0.003),

    # Formas geométricas / abstractas (ruido Perlin)
    'abstract_3d_mesh.png':   lambda w, h: make_perlin_tip(w, h, seed=40, scale=6.0, octaves=5, contrast=2.0),
    'abstract_glitch.png':    lambda w, h: make_perlin_tip(w, h, seed=41, scale=8.0, octaves=6, contrast=2.5),
    'abstract_kaleidoscope.png': lambda w, h: make_perlin_tip(w, h, seed=42, scale=5.0, octaves=4, contrast=1.8),
    'abstract_pointillism.png':  lambda w, h: make_splatter_tip(w, h, seed=43, num_drops=25),
    'abstract_polygons.png':  lambda w, h: make_perlin_tip(w, h, seed=44, scale=3.0, octaves=3, contrast=2.2),
    'canvas.png':             lambda w, h: make_perlin_tip(w, h, seed=50, scale=12.0, octaves=4, contrast=1.4),
    'carpenter_pencil.png':   lambda w, h: make_pencil_tip(w, h, seed=51, grain_freq=60, hardness=0.7),
    'compressed_stick.png':   lambda w, h: make_charcoal_tip(w, h, seed=52),
    'conte_crayon.png':       lambda w, h: make_charcoal_tip(w, h, seed=53),

    # Sprays
    'comic_60s.png':          lambda w, h: make_splatter_tip(w, h, seed=60, num_drops=35),
    'drips.png':              lambda w, h: make_splatter_tip(w, h, seed=61, num_drops=12),
    'halftone.png':           lambda w, h: make_splatter_tip(w, h, seed=62, num_drops=22),
    'high_contrast.png':      lambda w, h: make_ink_tip(w, h, seed=63, hardness=0.92, scatter=0.02),

    # Otros pinceles con texturas pequeñas
    'blackboard_chalk.png':   lambda w, h: make_charcoal_tip(w, h, seed=70),
    'cubes.png':              lambda w, h: make_perlin_tip(w, h, seed=71, scale=4.0, octaves=4, contrast=1.9),
    'digital_shader.png':     lambda w, h: make_perlin_tip(w, h, seed=72, scale=5.0, octaves=3, contrast=1.5),
    'gothic_pen.png':         lambda w, h: make_ink_tip(w, h, seed=73, hardness=0.96, scatter=0.01),
    'grid.png':               lambda w, h: make_perlin_tip(w, h, seed=74, scale=8.0, octaves=3, contrast=2.4),
    'hartz.png':              lambda w, h: make_charcoal_tip(w, h, seed=75),
    'ink_roller.png':         lambda w, h: make_ink_tip(w, h, seed=76, hardness=0.95, scatter=0.008),
    'metal_mesh.png':         lambda w, h: make_perlin_tip(w, h, seed=77, scale=10.0, octaves=4, contrast=2.0),
    'newsprint.png':          lambda w, h: make_perlin_tip(w, h, seed=78, scale=14.0, octaves=5, contrast=1.6),
    'nikko_rull.png':         lambda w, h: make_ink_tip(w, h, seed=79, hardness=0.97, scatter=0.006),
    'paint_flat.png':         lambda w, h: make_pencil_tip(w, h, seed=80, grain_freq=20, hardness=0.9),
    'palette_knife.png':      lambda w, h: make_pencil_tip(w, h, seed=81, grain_freq=30, hardness=0.85),
    'shale.png':              lambda w, h: make_charcoal_tip(w, h, seed=82),
    'urban_floor.png':        lambda w, h: make_perlin_tip(w, h, seed=83, scale=9.0, octaves=5, contrast=1.7),
    'vhs_noise.png':          lambda w, h: make_perlin_tip(w, h, seed=84, scale=12.0, octaves=6, contrast=2.1),
    'wax_stick.png':          lambda w, h: make_charcoal_tip(w, h, seed=85),
}

# ─────────────────────────────────────────────────────────────
# Ejecución principal
# ─────────────────────────────────────────────────────────────

def main():
    textures_path = os.path.abspath(TEXTURES_DIR)
    if not os.path.isdir(textures_path):
        print(f"ERROR: Directorio no encontrado: {textures_path}")
        return

    all_files = [f for f in os.listdir(textures_path) if f.lower().endswith('.png')]
    small_files = []
    for fname in sorted(all_files):
        fpath = os.path.join(textures_path, fname)
        size = os.path.getsize(fpath)
        if size < SIZE_THRESHOLD_BYTES:
            small_files.append((fname, size))

    print(f"\n🎨 ArtFlow Studio — Regenerador de Texturas")
    print(f"  Directorio: {textures_path}")
    print(f"  Total PNGs: {len(all_files)}")
    print(f"  Texturas pequeñas (< {SIZE_THRESHOLD_BYTES} bytes): {len(small_files)}")
    print()

    regenerated = 0
    skipped = 0

    for fname, old_size in small_files:
        fpath = os.path.join(textures_path, fname)

        if fname in GENERATORS:
            print(f"[✓] Regenerando: {fname}  (era {old_size} bytes)")
            try:
                pixels = GENERATORS[fname](OUTPUT_SIZE, OUTPUT_SIZE)
                _write_png_grayscale(fpath, pixels, OUTPUT_SIZE, OUTPUT_SIZE)
                regenerated += 1
            except Exception as e:
                print(f"    ERROR: {e}")
        else:
            print(f"[~] Sin generador para: {fname}  ({old_size} bytes) — usando Perlin genérico")
            try:
                seed = sum(ord(c) for c in fname)
                pixels = make_perlin_tip(OUTPUT_SIZE, OUTPUT_SIZE, seed=seed, scale=5.0, octaves=4)
                _write_png_grayscale(fpath, pixels, OUTPUT_SIZE, OUTPUT_SIZE)
                regenerated += 1
            except Exception as e:
                print(f"    ERROR: {e}")
                skipped += 1

    print(f"\n✅ Terminado: {regenerated} texturas regeneradas, {skipped} omitidas.")
    print(f"   Nuevas texturas: {OUTPUT_SIZE}x{OUTPUT_SIZE} px en escala de grises.")


if __name__ == '__main__':
    main()
