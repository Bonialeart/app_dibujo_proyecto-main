"""
generate_grain_textures.py  
Genera texturas de grano de papel para pinceles de acuarela.
"""
import numpy as np
from PIL import Image, ImageFilter
import os

SIZE = 512
OUT_DIR = r"E:\Rescate_Proyecto\assets\brushes"
BUILD_DIR = r"E:\Rescate_Proyecto\build_mingw\assets\brushes"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(BUILD_DIR, exist_ok=True)

def smooth_noise(scale, octaves=4, seed=0):
    r = np.random.default_rng(seed)
    h = np.zeros((SIZE, SIZE), np.float32)
    amp = 1.0
    for o in range(octaves):
        freq = max(int(scale * (2 ** o)), 2)
        small = r.random((freq, freq)).astype(np.float32)
        big = np.array(Image.fromarray((small * 255).astype(np.uint8)).resize(
            (SIZE, SIZE), Image.BICUBIC)) / 255.0
        h += big * amp
        amp *= 0.5
    h -= h.min(); mx = h.max()
    if mx > 0: h /= mx
    return h

def save(arr, name):
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), mode='L')
    for d in [OUT_DIR, BUILD_DIR]:
        p = os.path.join(d, name)
        img.save(p)
    print(f"  {name}")

# ─── 1. Papel de acuarela (Cold Press) ────────────────────────────────────────
def make_watercolor_paper():
    # Múltiples frecuencias que simulan las fibras del papel
    n1 = smooth_noise(8,  octaves=4, seed=1)   # Rugosidad media
    n2 = smooth_noise(24, octaves=3, seed=2)   # Fibras finas
    n3 = smooth_noise(3,  octaves=2, seed=3)   # Ondulaciones grandes

    # El papel cold-press tiene textura media-gruesa
    grain = n1 * 0.50 + n2 * 0.35 + n3 * 0.15

    # Normalizar al rango [0.25, 1.0] — que los valles nunca sean negros totales
    grain = 0.25 + grain * 0.75

    # Ligero blur para suavizar (papel tiene textura suave, no pixels)
    img = Image.fromarray((grain * 255).astype(np.uint8))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    grain = np.array(img).astype(np.float32) / 255.0

    save(grain, "grain_watercolor_paper.png")

# ─── 2. Papel de boceto (liso) ────────────────────────────────────────────────
def make_sketch_paper():
    n1 = smooth_noise(16, octaves=3, seed=10)
    n2 = smooth_noise(40, octaves=2, seed=11)
    grain = n1 * 0.6 + n2 * 0.4
    grain = 0.45 + grain * 0.55   # Más uniforme (papel liso)
    img = Image.fromarray((grain * 255).astype(np.uint8))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
    grain = np.array(img).astype(np.float32) / 255.0
    save(grain, "grain_sketch_paper.png")

# ─── 3. Canvas de pintura ─────────────────────────────────────────────────────
def make_canvas():
    # Canvas tiene textura diagonal de tejido
    y_i, x_i = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
    # Patrón de tejido cruzado
    weave = np.sin(x_i * 0.25) * np.sin(y_i * 0.25)
    weave = (weave + 1.0) * 0.5   # [0..1]
    # Ruido para irregularidades del tejido
    noise = smooth_noise(6, octaves=3, seed=20)
    grain = weave * 0.55 + noise * 0.45
    grain = 0.20 + grain * 0.80
    img = Image.fromarray((grain * 255).astype(np.uint8))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
    grain = np.array(img).astype(np.float32) / 255.0
    save(grain, "grain_canvas.png")

# ─── 4. Charcoal/Carbón ───────────────────────────────────────────────────────
def make_charcoal():
    n1 = smooth_noise(32, octaves=2, seed=30)  # grano fino
    n2 = smooth_noise(8,  octaves=3, seed=31)  # variación media
    grain = n1 * 0.70 + n2 * 0.30
    grain = 0.15 + grain * 0.85   # Carbon necesita valles muy oscuros
    img = Image.fromarray((grain * 255).astype(np.uint8))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
    grain = np.array(img).astype(np.float32) / 255.0
    save(grain, "grain_charcoal.png")

print("=== Generando texturas de grano ===")
make_watercolor_paper()
make_sketch_paper()
make_canvas()
make_charcoal()
print("\n✅ Listo.")
