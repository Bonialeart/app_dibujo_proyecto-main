import os
import random
import math
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageChops, ImageEnhance

def create_oil_sketch_tip():
    size = 256
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    
    # 20-30 thin lines
    for _ in range(30):
        w = random.randint(2, 6)
        h = random.randint(size//3, size-20)
        x = (size - w)//2 + random.randint(-20, 20)
        y = (size - h)//2 + random.randint(-40, 40)
        opacity = random.randint(100, 255)
        d.rectangle([x, y, x+w, y+h], fill=(255, 255, 255, opacity))
        
    return image.filter(ImageFilter.GaussianBlur(1))

def create_oil_thick_tip():
    size = 256
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    
    # Base blob (irregular)
    center = size//2
    points = []
    for angle in range(0, 360, 20):
        r = size//2.5 + random.randint(-20, 20)
        rad = math.radians(angle)
        points.append((center + r*math.cos(rad), center + r*math.sin(rad)))
        
    d.polygon(points, fill=(255, 255, 255, 255))
    
    return image.filter(ImageFilter.GaussianBlur(3))

def create_oil_dry_tip():
    size = 256
    # Create base shape
    base = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(base)
    d.ellipse((20, 20, size-20, size-20), fill=200)
    base = base.filter(ImageFilter.GaussianBlur(10))
    
    # Create noise
    noise = Image.effect_noise((size, size), 50).convert("L")
    
    # Contrast boost (Manual)
    enhancer = ImageEnhance.Contrast(noise)
    noise = enhancer.enhance(3.0)
    
    # Mask
    final_alpha = ImageChops.multiply(base, noise)
    
    return Image.merge("RGBA", (Image.new("L", (size, size), 255),
                                Image.new("L", (size, size), 255), 
                                Image.new("L", (size, size), 255), 
                                final_alpha))

def create_oil_rake_tip():
    size = 256
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    
    num_bristles = 12
    spacing = size // num_bristles
    
    for i in range(num_bristles):
        x = i * spacing + 10
        w = random.randint(2, 5)
        h = random.randint(size//2, size-10)
        y = (size - h) // 2 + random.randint(-30, 30)
        d.rectangle([x, y, x+w, y+h], fill=(255, 255, 255, 255))
        
    return image.filter(ImageFilter.GaussianBlur(0.5))

def create_smudge_tip():
    size = 256
    # Cloud-like noise
    noise = Image.effect_noise((64, 64), 10).resize((size, size), Image.BICUBIC).convert("L")
    
    # Soft mask
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((0, 0, size, size), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(30))
    
    final_alpha = ImageChops.multiply(noise, mask)
    
    return Image.merge("RGBA", (Image.new("L", (size, size), 255),
                                Image.new("L", (size, size), 255), 
                                Image.new("L", (size, size), 255), 
                                final_alpha))

def create_toothbrush_tip():
    size = 256
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    
    center = size // 2
    for _ in range(500):
        # Gaussian distribution
        r = random.gauss(0, size // 3)
        theta = random.uniform(0, 2 * math.pi)
        
        if abs(r) > size // 2: continue
        
        x = center + r * math.cos(theta)
        y = center + r * math.sin(theta)
        
        radius = random.randint(1, 4)
        opacity = random.randint(50, 255)
        d.ellipse([x, y, x+radius, y+radius], fill=(255, 255, 255, opacity))
        
    return image

def main():
    output_dir = r"e:\app_dibujo_proyecto-main\assets\textures"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    funcs = {
        "oil_sketch.png": create_oil_sketch_tip,
        "oil_thick.png": create_oil_thick_tip,
        "oil_dry.png": create_oil_dry_tip,
        "oil_rake.png": create_oil_rake_tip,
        "smudge_textured.png": create_smudge_tip,
        "toothbrush_spray.png": create_toothbrush_tip
    }

    print("Generating fixed textures...")
    for filename, func in funcs.items():
        img = func()
        path = os.path.join(output_dir, filename)
        img.save(path, "PNG")
        print(f"  Saved {filename}")

if __name__ == "__main__":
    main()
