import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import random
import math

OUTPUT_DIR = r"e:\app_dibujo_proyecto-main\src\assets\brushes\tips"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def save_tip(name, img):
    img.save(os.path.join(OUTPUT_DIR, name))
    print(f"Generated {name}")

def gen_hard_round(size=256):
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    padding = size * 0.05
    draw.ellipse([padding, padding, size-padding, size-padding], fill=255)
    return img

def gen_soft_round(size=256):
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    center = size // 2
    r = size // 4
    draw.ellipse([center-r, center-r, center+r, center+r], fill=255)
    return img.filter(ImageFilter.GaussianBlur(radius=size/6))

def gen_pencil_noise(size=256):
    center = size / 2
    y, x = np.ogrid[:size, :size]
    dist = np.sqrt((x - center)**2 + (y - center)**2)
    mask = np.clip(1.0 - dist / (size/2), 0, 1)
    
    noise = np.random.rand(size, size).astype(np.float32)
    data = mask * noise * 255
    data = np.clip(data, 0, 255).astype(np.uint8)
    return Image.fromarray(data, mode="L")

def gen_charcoal(size=256):
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    
    for _ in range(20):
        cx = random.randint(50, 206)
        cy = random.randint(50, 206)
        r = random.randint(10, 40)
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=random.randint(100, 200))
    
    arr = np.array(img).astype(np.float32)
    noise = np.random.normal(1.0, 0.3, arr.shape)
    arr = arr * noise
    
    y, x = np.ogrid[:size, :size]
    dist = np.sqrt((x - 128)**2 + (y - 128)**2)
    falloff = np.clip(1.0 - (dist/128)**3, 0, 1)
    
    arr = arr * falloff
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, mode="L")

def gen_square(size=256):
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    p = 20
    draw.rectangle([p, p, size-p, size-p], fill=255)
    return img

def gen_bristle_round(size=256):
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    center = size // 2
    
    for _ in range(400):
        r_dist = random.triangular(0, size//2 - 10, 0)
        angle = random.uniform(0, 6.28)
        x = center + math.cos(angle) * r_dist
        y = center + math.sin(angle) * r_dist
        r_spot = random.randint(1, 4)
        opacity = random.randint(50, 255)
        draw.ellipse([x-r_spot, y-r_spot, x+r_spot, y+r_spot], fill=opacity)
        
    return img

def main():
    save_tip("tip_hard.png", gen_hard_round())
    save_tip("tip_soft.png", gen_soft_round())
    save_tip("tip_pencil.png", gen_pencil_noise())
    save_tip("tip_charcoal.png", gen_charcoal())
    save_tip("tip_square.png", gen_square())
    save_tip("tip_bristle.png", gen_bristle_round())
    
    cloud = gen_soft_round()
    arr = np.array(cloud)
    noise = np.random.rand(*arr.shape)
    arr = arr * (0.5 + 0.5*noise)
    save_tip("tip_watercolor.png", Image.fromarray(arr.astype(np.uint8)))

if __name__ == "__main__":
    main()
